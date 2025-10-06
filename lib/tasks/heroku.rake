namespace :heroku do
  desc "Install Emscripten and MLX42 headers on Heroku"
  task :setup_mlx42 do
    puts "-----> Setting up Emscripten and MLX42 headers"

    # Install Emscripten to /app/.emsdk
    emsdk_dir = "/app/.emsdk"

    unless Dir.exist?(emsdk_dir)
      puts "-----> Installing Emscripten SDK"
      unless system("git clone --depth 1 https://github.com/emscripten-core/emsdk.git #{emsdk_dir}")
        puts "-----> ERROR: Failed to clone emsdk"
        exit 1
      end

      Dir.chdir(emsdk_dir) do
        unless system("./emsdk install latest")
          puts "-----> ERROR: Failed to install emsdk"
          exit 1
        end
        unless system("./emsdk activate latest")
          puts "-----> ERROR: Failed to activate emsdk"
          exit 1
        end
      end
    else
      puts "-----> Emscripten SDK already installed"
    end

    # Add emcc to PATH by sourcing emsdk_env.sh
    puts "-----> Activating Emscripten environment"
    system("bash -c 'source #{emsdk_dir}/emsdk_env.sh'")

    # Install MLX42 headers to /MLX42/include
    mlx42_include_dir = "/MLX42/include"

    unless Dir.exist?(mlx42_include_dir)
      puts "-----> Installing MLX42 headers"
      unless system("git clone --depth 1 https://github.com/codam-coding-college/MLX42.git /tmp/mlx42_clone")
        puts "-----> ERROR: Failed to clone MLX42"
        exit 1
      end

      FileUtils.mkdir_p("/MLX42")
      FileUtils.cp_r("/tmp/mlx42_clone/include", "/MLX42/")
      FileUtils.rm_rf("/tmp/mlx42_clone")
      puts "-----> MLX42 headers installed to /MLX42/include"
    else
      puts "-----> MLX42 headers already installed"
    end

    puts "-----> Setup complete"
  end
end
