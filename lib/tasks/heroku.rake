namespace :heroku do
  desc "Build MLX42 for WebAssembly on Heroku"
  task :build_mlx42 do
    puts "-----> Installing Emscripten and MLX42"

    # Define directories
    home_dir = ENV["HOME"]
    cache_dir = "#{home_dir}/.cache"
    emsdk_dir = "#{home_dir}/.emsdk"
    mlx42_dir = "#{home_dir}/.mlx42"
    install_dir = Rails.root.join("vendor", "mlx42")

    FileUtils.mkdir_p(cache_dir)

    # Install Emscripten if not cached
    if !Dir.exist?("#{cache_dir}/emsdk")
      puts "-----> Installing Emscripten SDK"
      system("git clone --depth 1 https://github.com/emscripten-core/emsdk.git #{cache_dir}/emsdk")
      Dir.chdir("#{cache_dir}/emsdk") do
        system("./emsdk install latest")
        system("./emsdk activate latest")
      end
    else
      puts "-----> Using cached Emscripten SDK"
    end

    # Copy emsdk to home directory
    FileUtils.cp_r("#{cache_dir}/emsdk", emsdk_dir) unless Dir.exist?(emsdk_dir)

    # Source Emscripten environment
    emsdk_env = `bash -c 'source #{emsdk_dir}/emsdk_env.sh && env'`
    emsdk_env.each_line do |line|
      key, value = line.chomp.split("=", 2)
      ENV[key] = value if value
    end

    # Build MLX42 for WebAssembly if not cached
    if !Dir.exist?("#{cache_dir}/mlx42")
      puts "-----> Building MLX42 for WebAssembly"
      system("git clone --depth 1 https://github.com/codam-coding-college/MLX42.git #{mlx42_dir}")

      Dir.chdir(mlx42_dir) do
        FileUtils.mkdir_p("build")
        Dir.chdir("build") do
          system("#{emsdk_dir}/upstream/emscripten/emcmake cmake .. -DCMAKE_BUILD_TYPE=Release")
          system("#{emsdk_dir}/upstream/emscripten/emmake make -j$(nproc)")
        end
      end

      # Cache the built library
      FileUtils.mkdir_p("#{cache_dir}/mlx42")
      FileUtils.cp_r("#{mlx42_dir}/build", "#{cache_dir}/mlx42/")
      FileUtils.cp_r("#{mlx42_dir}/include", "#{cache_dir}/mlx42/")
    else
      puts "-----> Using cached MLX42"
    end

    # Copy MLX42 to vendor directory
    puts "-----> Installing MLX42 to vendor directory"
    FileUtils.mkdir_p(install_dir)
    FileUtils.cp_r(Dir["#{cache_dir}/mlx42/*"], install_dir)

    # Copy the compiled library to app/assets
    puts "-----> Copying libmlx42.a to app/assets"
    lib_path = "#{cache_dir}/mlx42/build/libmlx42.a"
    if File.exist?(lib_path)
      FileUtils.cp(lib_path, Rails.root.join("app", "assets", "libmlx42_web.a"))
      puts "-----> MLX42 installation complete"
    else
      puts "-----> ERROR: libmlx42.a not found at #{lib_path}"
      exit 1
    end
  end
end
