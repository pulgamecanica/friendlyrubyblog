class Mlx42CompilerService
  WRAPPER_TEMPLATE = <<~C
    #include <MLX42/MLX42.h>
    #include <emscripten.h>
    #include <emscripten/html5.h>
    #include <stdlib.h>
    #include <stdio.h>

    #define WIDTH %{width}
    #define HEIGHT %{height}

    mlx_t *mlx;

    // User must define this function
    extern void user_main(int argc, char **argv);

    static void emscripten_main_loop(void) {
      mlx_loop(mlx);
    }

    int main(int argc, char **argv) {
      if (!(mlx = mlx_init(WIDTH, HEIGHT, "MLX42", true))) {
        puts(mlx_strerror(mlx_errno));
        return EXIT_FAILURE;
      }

      user_main(argc, argv);

      emscripten_set_main_loop(emscripten_main_loop, 0, true);
      mlx_terminate(mlx);
      return EXIT_SUCCESS;
    }
  C

  MLX42_LIB_PATH = ENV.fetch("MLX42_LIB_PATH", "/home/pulgamecanica/friendlyrubyblog/app/assets/libmlx42_web.a")

  # Arcade C SDK — auto-linked whenever the block is owned by a Game so
  # submissions get the `arcade_*` functions for free via `#include <arcade.h>`.
  ARCADE_SDK_DIR = Rails.root.join("vendor", "arcade_sdk").to_s
  ARCADE_SDK_SOURCE = File.join(ARCADE_SDK_DIR, "arcade.c")

  def initialize(block)
    @block = block
  end

  def compile
    Dir.mktmpdir do |dir|
      wrapper_file = File.join(dir, "wrapper_main.c")
      output_base = File.join(dir, "mlx42_output")
      assets_dir = File.join(dir, "assets")

      # Create assets directory and copy assets
      if @block.assets.attached?
        Dir.mkdir(assets_dir)
        @block.assets.each do |asset|
          File.open(File.join(assets_dir, asset.filename.to_s), "wb") do |file|
            file.write(asset.download)
          end
        end
      end

      # Write user files (multi-file or legacy single file)
      user_c_files = []

      if @block.multi_file?
        # New multi-file format
        @block.files.each do |file_data|
          filename = file_data["filename"]
          content = file_data["content"]
          file_path = File.join(dir, filename)

          FileUtils.mkdir_p(File.dirname(file_path))
          File.write(file_path, content)

          # Track .c files for compilation
          user_c_files << file_path if filename.end_with?(".c")
        end
      else
        # Legacy single file format
        user_file = File.join(dir, "user_code.c")
        File.write(user_file, @block.text)
        user_c_files << user_file
      end

      # Write wrapper with substituted dimensions
      wrapper_code = WRAPPER_TEMPLATE % { width: @block.width, height: @block.height }
      File.write(wrapper_file, wrapper_code)

      # Compile with emcc (pass all .c files)
      compile_argv = build_compile_argv(wrapper_file, user_c_files, output_base, dir)

      # NOTE: pass argv, not a joined string. Open3.capture3 with an array
      # bypasses the shell entirely, so any game-supplied compiler_args can
      # never be interpreted as shell metacharacters.
      stdout, stderr, status = Open3.capture3(*compile_argv)

      if status.success?
        attach_compiled_files(output_base)
        @block.clear_compilation_error
        @block.save!
        { success: true }
      else
        error_message = "Compilation failed:\n#{stderr}\n#{stdout}"
        @block.set_compilation_error(error_message)
        @block.save!
        { success: false, error: error_message }
      end
    end
  rescue => e
    error_message = "Compilation error: #{e.message}"
    @block.set_compilation_error(error_message)
    @block.save!
    { success: false, error: error_message }
  end

  private

  def build_compile_argv(wrapper_file, user_c_files, output_base, working_dir)
    argv = [
      "emcc",
      "-DWEB",
      "-O3",
      "-I", "/usr/local/include",
      "-I", Rails.root.join("MLX42_headers").to_s,
      "-I", working_dir   # include working dir for local headers
    ]

    # When the block is owned by a Game, auto-expose the Arcade SDK and
    # link arcade.c. Blog blocks never see arcade.h — keeping the two
    # worlds cleanly separated even at the compile layer.
    if arcade_mode?
      argv += [ "-I", ARCADE_SDK_DIR ]
    end

    argv += [
      "-pthread",
      wrapper_file,
      *user_c_files
    ]

    argv << ARCADE_SDK_SOURCE if arcade_mode?

    argv += [
      "-o", "#{output_base}.js",
      MLX42_LIB_PATH,
      "-s", "USE_GLFW=3",
      "-s", "USE_WEBGL2=1",
      "-s", "FULL_ES3=1",
      "-s", "WASM=1",
      "-s", "NO_EXIT_RUNTIME=1",
      "-s", 'EXPORTED_RUNTIME_METHODS=["ccall","cwrap","UTF8ToString","stringToUTF8","lengthBytesUTF8"]',
      "-s", "EXPORTED_FUNCTIONS=[\"_main\",\"_malloc\",\"_free\"]",
      "-s", "ALLOW_MEMORY_GROWTH",
      "-s", "MODULARIZE=1",
      "-s", "EXPORT_NAME=createMlx42Module"
    ]

    if @block.assets.attached?
      argv += [ "--preload-file", "#{working_dir}/assets" ]
    end

    # Custom compiler_args: still accepted for blog blocks (your own code),
    # but explicitly ignored for arcade submissions — we don't want a game
    # submitter to disable optimizations or swap linker flags.
    unless arcade_mode?
      custom_args = @block.compiler_args.to_s.strip.split(/\s+/).reject(&:empty?)
      argv += custom_args
    end

    argv
  end

  def arcade_mode?
    @block.owner.is_a?(Game)
  end

  def attach_compiled_files(output_base)
    # Attach WASM file
    wasm_path = "#{output_base}.wasm"
    if File.exist?(wasm_path)
      @block.wasm_file.attach(
        io: File.open(wasm_path),
        filename: "mlx42_output.wasm",
        content_type: "application/wasm"
      )
    end

    # Attach JS file
    js_path = "#{output_base}.js"
    if File.exist?(js_path)
      @block.js_file.attach(
        io: File.open(js_path),
        filename: "mlx42_output.js",
        content_type: "application/javascript"
      )
    end

    # Attach data file if it exists
    data_path = "#{output_base}.data"
    if File.exist?(data_path)
      @block.data_file.attach(
        io: File.open(data_path),
        filename: "mlx42_output.data",
        content_type: "application/octet-stream"
      )
    end
  end
end
