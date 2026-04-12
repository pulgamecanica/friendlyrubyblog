require "open3"
require "uri"
require "zip"

class GameIngestionService
  # Game repos are self-contained: they include their own Makefile, MLX42 as
  # a submodule, and a build target that produces wasm/js artifacts in an
  # output directory (default: `web/`).
  #
  # This service:
  #   1. Clones the repo (with --recursive for submodules) or extracts a zip.
  #   2. Runs `make` (or a configurable make target).
  #   3. Picks up .wasm, .js, .html, .css, .data files from the output dir.
  #   4. Attaches them to the Game's Mlx42Block.
  #
  # The server does NOT invoke emcc directly — that's the Makefile's job.
  # Mlx42CompilerService is for blog blocks where the author writes C inline.
  #
  # SECURITY NOTE: `make` runs arbitrary shell commands. Before opening
  # submissions to the public, wrap the build step in a sandboxed container
  # with no network, CPU + memory + wall-clock limits.

  GIT_CLONE_TIMEOUT = 120 # seconds — submodule clones take longer
  BUILD_TIMEOUT     = 300 # seconds (5 min) for `make`
  MAX_ZIP_BYTES     = 50.megabytes
  MAX_ARTIFACT_BYTES = 20.megabytes # any single output file

  ALLOWED_GIT_SCHEMES = %w[https].freeze
  ALLOWED_GIT_HOSTS   = %w[github.com gitlab.com bitbucket.org codeberg.org].freeze

  # File extensions we pick up from the output directory.
  ARTIFACT_EXTS = %w[.wasm .js .html .css .data .json .mem .png .jpg .svg].freeze

  CONTENT_TYPES = {
    ".wasm" => "application/wasm",
    ".js"   => "application/javascript",
    ".html" => "text/html",
    ".css"  => "text/css",
    ".data" => "application/octet-stream",
    ".json" => "application/json",
    ".mem"  => "application/octet-stream",
    ".png"  => "image/png",
    ".jpg"  => "image/jpeg",
    ".svg"  => "image/svg+xml"
  }.freeze

  Error = Class.new(StandardError)

  def self.call(game)
    new(game).call
  end

  def initialize(game)
    @game = game
  end

  def call
    @game.update!(status: :compiling)

    Dir.mktmpdir("arcade_ingest_") do |work_dir|
      src_dir = case @game.source["kind"]
      when "git" then fetch_from_git!(work_dir)
      when "zip" then extract_zip!(work_dir)
      else raise Error, "unknown source kind: #{@game.source['kind'].inspect}"
      end

      run_make!(src_dir)
      attach_artifacts!(src_dir)
    end

    @game.reload
    @game.update!(status: :playable)
    { ok: true }
  rescue Error => e
    fail_ingestion!(e.message)
    { ok: false, error: e.message }
  rescue => e
    Rails.logger.error("[arcade ingest] unexpected: #{e.class}: #{e.message}")
    fail_ingestion!("Unexpected ingestion error: #{e.message}")
    { ok: false, error: e.message }
  end

  private

  # ------------------------------------------------------------------
  # git clone (with submodules)
  # ------------------------------------------------------------------
  def fetch_from_git!(work_dir)
    url = @game.source["git_url"].to_s.strip
    ref = @game.source["git_ref"].presence

    validate_git_url!(url)

    clone_dir = File.join(work_dir, "src")
    clone_url = maybe_inject_token(url)

    args = [
      "git", "clone",
      "--recursive",          # MLX42 is typically a submodule
      "--depth", "1",
      "--single-branch",
      "--no-tags"
    ]
    args += [ "--branch", ref ] if ref && ref.match?(/\A[\w\-.\/]+\z/)
    args += [ clone_url, clone_dir ]

    git_env = {
      "GIT_TERMINAL_PROMPT" => "0",
      "GIT_ASKPASS"         => "echo",
      "GIT_CONFIG_NOSYSTEM" => "1",
      "HOME"                => work_dir
    }

    stdout, stderr, status = Timeout.timeout(GIT_CLONE_TIMEOUT + 5) do
      Open3.capture3(git_env, *args)
    end

    unless status.success?
      msg = stderr.strip.presence || stdout.strip.presence || "unknown error"

      if msg.include?("Authentication failed") || msg.include?("could not read Username")
        raise Error, "git clone failed: could not access the repository. " \
                     "Is it private? Only public repositories can be submitted.\n\n" \
                     "Make sure the repo is set to Public on GitHub, then try again."
      else
        raise Error, "git clone failed:\n#{msg}"
      end
    end

    clone_dir
  rescue Timeout::Error
    raise Error, "git clone timed out after #{GIT_CLONE_TIMEOUT}s"
  end

  def maybe_inject_token(url)
    token = ENV["GITHUB_TOKEN"]
    return url if token.blank?

    uri = URI.parse(url)
    return url unless uri.host.to_s.downcase.include?("github.com")

    uri.userinfo = "x-access-token:#{token}"
    uri.to_s
  end

  def validate_git_url!(url)
    raise Error, "git URL is required" if url.blank?

    uri = URI.parse(url)
    unless ALLOWED_GIT_SCHEMES.include?(uri.scheme)
      raise Error, "git URL must use https:// (got: #{uri.scheme.inspect})"
    end

    host = uri.host.to_s.downcase
    unless ALLOWED_GIT_HOSTS.any? { |h| host == h || host.end_with?(".#{h}") }
      raise Error, "git host not allowed: #{host} (allowed: #{ALLOWED_GIT_HOSTS.join(', ')})"
    end
  rescue URI::InvalidURIError
    raise Error, "invalid git URL"
  end

  # ------------------------------------------------------------------
  # zip extraction
  # ------------------------------------------------------------------
  def extract_zip!(work_dir)
    archive = @game.source_archive
    raise Error, "no zip uploaded" unless archive.attached?

    if archive.byte_size > MAX_ZIP_BYTES
      raise Error, "zip is larger than #{MAX_ZIP_BYTES / 1.megabyte}MB"
    end

    extract_dir = File.join(work_dir, "src")
    FileUtils.mkdir_p(extract_dir)

    zip_path = File.join(work_dir, "source.zip")
    File.open(zip_path, "wb") { |f| f.write(archive.download) }

    Zip::File.open(zip_path) do |zip_file|
      zip_file.each do |entry|
        raise Error, "zip contains a symlink: #{entry.name}" if entry.symlink?
        next if entry.directory?

        safe_path = sanitize_extraction_path!(entry.name, extract_dir)
        FileUtils.mkdir_p(File.dirname(safe_path))
        entry.extract(safe_path) { true }
      end
    end

    collapse_single_top_dir!(extract_dir)
    extract_dir
  rescue Zip::Error => e
    raise Error, "invalid zip: #{e.message}"
  end

  def sanitize_extraction_path!(entry_name, extract_dir)
    if entry_name.start_with?("/") || entry_name.include?("..")
      raise Error, "zip entry has unsafe path: #{entry_name}"
    end

    path = File.expand_path(entry_name, extract_dir)
    unless path.start_with?(File.expand_path(extract_dir) + File::SEPARATOR)
      raise Error, "zip entry escapes extraction dir: #{entry_name}"
    end

    path
  end

  def collapse_single_top_dir!(extract_dir)
    children = Dir.children(extract_dir)
    return unless children.size == 1

    only = File.join(extract_dir, children.first)
    return unless File.directory?(only)

    Dir.children(only).each do |name|
      FileUtils.mv(File.join(only, name), File.join(extract_dir, name))
    end
    FileUtils.rmdir(only)
  end

  # ------------------------------------------------------------------
  # build: run make
  # ------------------------------------------------------------------
  def run_make!(src_dir)
    target = make_target
    cmd = target.blank? ? [ "make" ] : [ "make", target ]

    raise Error, "no Makefile found in repository" unless File.exist?(File.join(src_dir, "Makefile"))

    Rails.logger.info("[arcade ingest] running: #{cmd.join(' ')} in #{src_dir}")

    stdout, stderr, status = Timeout.timeout(BUILD_TIMEOUT + 5) do
      Open3.capture3(*cmd, chdir: src_dir)
    end

    unless status.success?
      # Truncate huge make output to something readable in the error panel.
      output = [ stderr, stdout ].map(&:strip).reject(&:blank?).join("\n\n")
      truncated = output.last(4000)
      raise Error, "make failed (exit #{status.exitstatus}):\n#{truncated}"
    end
  rescue Timeout::Error
    raise Error, "build timed out after #{BUILD_TIMEOUT}s"
  end

  # ------------------------------------------------------------------
  # pick up artifacts from the output directory
  # ------------------------------------------------------------------
  def attach_artifacts!(src_dir)
    out = File.join(src_dir, output_dir)

    unless File.directory?(out)
      raise Error, "output directory '#{output_dir}' not found after build. " \
                   "Expected the Makefile to produce .wasm/.js files in '#{output_dir}/'.\n\n" \
                   "Contents of repo root:\n#{Dir.children(src_dir).sort.join(', ')}"
    end

    all_files = Dir.children(out)
                    .select { |f| ARTIFACT_EXTS.include?(File.extname(f).downcase) }
                    .sort

    wasm = all_files.find { |f| f.end_with?(".wasm") }
    js   = all_files.find { |f| f.end_with?(".js") }
    html = all_files.find { |f| f.end_with?(".html") }

    raise Error, "no .wasm file found in '#{output_dir}/'" unless wasm
    raise Error, "no .js file found in '#{output_dir}/'" unless js

    Game.transaction do
      @game.mlx42_block&.destroy

      block = Mlx42Block.new(owner: @game, data: {
        "compilation_status" => "success",
        "compilation_completed_at" => Time.current.iso8601,
        "entry_html" => html || "index.html" # the HTML file the iframe loads
      })
      block.save!

      # Attach ALL output files as game_artifacts. They're served by a proxy
      # controller at a consistent URL path so relative references between
      # them (demo.js loading demo.wasm) work correctly.
      all_files.each do |filename|
        path = File.join(out, filename)
        size = File.size(path)

        if size > MAX_ARTIFACT_BYTES
          raise Error, "'#{filename}' is #{(size / 1.megabyte.to_f).round(1)}MB — max #{MAX_ARTIFACT_BYTES / 1.megabyte}MB"
        end

        ext = File.extname(filename).downcase
        ct  = CONTENT_TYPES[ext] || "application/octet-stream"

        block.game_artifacts.attach(
          io:           File.open(path),
          filename:     filename,
          content_type: ct
        )
      end

      # If there's no HTML file in the output, generate a minimal one that
      # loads the JS (which in turn loads the wasm). This covers repos whose
      # Makefile only outputs .js + .wasm without a .html wrapper.
      unless html
        generate_fallback_html!(block, js)
      end

      # Store source files for display on the game page
      store_source_files!(block, src_dir)
    end
  end

  def generate_fallback_html!(block, js_filename)
    html = <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <style>body{margin:0;background:#000;overflow:hidden}canvas{display:block;width:100vw;height:100vh}</style>
      </head>
      <body>
        <canvas id="canvas"></canvas>
        <script>var Module={canvas:document.getElementById('canvas')}</script>
        <script src="#{js_filename}"></script>
      </body>
      </html>
    HTML

    block.game_artifacts.attach(
      io:           StringIO.new(html),
      filename:     "index.html",
      content_type: "text/html"
    )
    block.data = block.data.to_h.merge("entry_html" => "index.html")
    block.save!
  end

  # Store the C/H source files in the block's data for code-view display.
  # This is optional — if it fails we still have the compiled artifacts.
  def store_source_files!(block, src_dir)
    source_exts = %w[.c .h .cpp .hpp .cc]
    files = []

    Dir.glob(File.join(src_dir, "**", "*")).sort.each do |path|
      next if File.directory?(path)
      rel = path.sub("#{src_dir}/", "")

      # Skip submodule source (MLX42/src/*, etc) — only the game's own code
      next if rel.start_with?("MLX42/") || rel.start_with?(".git")

      ext = File.extname(path).downcase
      next unless source_exts.include?(ext)

      content = File.read(path, encoding: "UTF-8", mode: "r") rescue next
      files << { "filename" => rel, "content" => content } if content.size < 500_000
    end

    block.files = files
    block.save! if files.any?
  end

  # ------------------------------------------------------------------
  # configurable per-game build settings
  # ------------------------------------------------------------------
  def make_target
    @game.metadata.to_h["make_target"].to_s.strip.presence
  end

  def output_dir
    @game.metadata.to_h["output_dir"].to_s.strip.presence || "web"
  end

  # ------------------------------------------------------------------
  # failure bookkeeping
  # ------------------------------------------------------------------
  def fail_ingestion!(message)
    next_status = @game.metadata.to_h["keep_for_review_on_failure"] ? :review : :discarded
    @game.update!(
      status: next_status,
      metadata: @game.metadata.to_h.merge("ingestion_error" => message)
    )
  end
end
