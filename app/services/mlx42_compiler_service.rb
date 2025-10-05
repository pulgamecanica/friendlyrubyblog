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

  def initialize(block)
    @block = block
  end

  def compile
    Dir.mktmpdir do |dir|
      user_file = File.join(dir, "user_code.c")
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

      # Write user code
      File.write(user_file, @block.text)

      # Write wrapper with substituted dimensions
      wrapper_code = WRAPPER_TEMPLATE % { width: @block.width, height: @block.height }
      File.write(wrapper_file, wrapper_code)

      # Compile with emcc
      compile_command = build_compile_command(wrapper_file, user_file, output_base, dir)

      stdout, stderr, status = Open3.capture3(compile_command)

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

  def build_compile_command(wrapper_file, user_file, output_base, working_dir)
    base_args = [
      "emcc",
      "-DWEB",
      "-O3",
      "-I", "/usr/local/include",
      "-I", "MLX42/include",
      "-pthread",
      wrapper_file,
      user_file,
      "-o", "#{output_base}.js",
      MLX42_LIB_PATH,
      "-s", "USE_GLFW=3",
      "-s", "USE_WEBGL2=1",
      "-s", "FULL_ES3=1",
      "-s", "WASM=1",
      "-s", "NO_EXIT_RUNTIME=1",
      "-s", "EXPORTED_RUNTIME_METHODS='[\"ccall\", \"cwrap\"]'",
      "-s", "ALLOW_MEMORY_GROWTH",
      "-s", "MODULARIZE=1",
      "-s", "EXPORT_NAME='createMlx42Module'"
    ]

    # Add preload-file for assets if they exist
    if @block.assets.attached?
      base_args += [ "--preload-file", "#{working_dir}/assets" ]
    end

    # Add custom compiler args if present
    custom_args = @block.compiler_args.to_s.strip.split(/\s+/)
    (base_args + custom_args).join(" ")
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
