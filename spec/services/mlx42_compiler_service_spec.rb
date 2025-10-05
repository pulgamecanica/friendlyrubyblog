require 'rails_helper'

RSpec.describe Mlx42CompilerService do
  let(:document) { create(:document) }
  let(:mlx42_block) do
    Mlx42Block.create!(
      document: document,
      position: 1,
      data: {
        "text" => "#include <MLX42/MLX42.h>\nvoid user_main(int argc, char **argv) { }",
        "width" => 800,
        "height" => 600
      }
    )
  end
  let(:service) { described_class.new(mlx42_block) }

  describe "#initialize" do
    it "stores the block" do
      expect(service.instance_variable_get(:@block)).to eq(mlx42_block)
    end
  end

  describe "#compile" do
    context "with successful compilation" do
      before do
        # Mock the compilation process
        allow(service).to receive(:attach_compiled_files)
        allow(Open3).to receive(:capture3).and_return(
          [ "", "", double(success?: true) ]
        )
      end

      it "returns success result" do
        result = service.compile

        expect(result[:success]).to be true
        expect(result[:error]).to be_nil
      end

      it "calls attach_compiled_files" do
        expect(service).to receive(:attach_compiled_files)

        service.compile
      end

      it "clears compilation error on success" do
        mlx42_block.set_compilation_error("old error")
        mlx42_block.save!

        service.compile

        mlx42_block.reload
        expect(mlx42_block.compilation_error).to be_nil
      end

      it "saves the block" do
        expect(mlx42_block).to receive(:save!).at_least(:once)

        service.compile
      end
    end

    context "with file attachment after successful compilation" do
      let(:temp_dir) { Dir.mktmpdir }
      let(:wasm_path) { File.join(temp_dir, "mlx42_output.wasm") }
      let(:js_path) { File.join(temp_dir, "mlx42_output.js") }
      let(:data_path) { File.join(temp_dir, "mlx42_output.data") }

      before do
        # Create fake compiled files
        File.write(wasm_path, "fake wasm content")
        File.write(js_path, "fake js content")
        File.write(data_path, "fake data content")

        # Mock Dir.mktmpdir to return our temp dir
        allow(Dir).to receive(:mktmpdir).and_yield(temp_dir)

        # Mock successful compilation
        allow(Open3).to receive(:capture3).and_return(
          [ "", "", double(success?: true) ]
        )
      end

      after do
        FileUtils.rm_rf(temp_dir) if File.exist?(temp_dir)
      end

      it "attaches WASM file when it exists" do
        service.compile

        mlx42_block.reload
        expect(mlx42_block.wasm_file).to be_attached
        expect(mlx42_block.wasm_file.filename.to_s).to eq("mlx42_output.wasm")
        expect(mlx42_block.wasm_file.content_type).to eq("application/wasm")
      end

      it "attaches JS file when it exists" do
        service.compile

        mlx42_block.reload
        expect(mlx42_block.js_file).to be_attached
        expect(mlx42_block.js_file.filename.to_s).to eq("mlx42_output.js")
        expect(mlx42_block.js_file.content_type).to eq("application/javascript")
      end

      it "attaches data file when it exists" do
        service.compile

        mlx42_block.reload
        expect(mlx42_block.data_file).to be_attached
        expect(mlx42_block.data_file.filename.to_s).to eq("mlx42_output.data")
        # Content type may be auto-detected by Active Storage
        expect(mlx42_block.data_file.content_type).to be_present
      end

      it "does not attach data file if it does not exist" do
        File.delete(data_path)

        service.compile

        mlx42_block.reload
        expect(mlx42_block.wasm_file).to be_attached
        expect(mlx42_block.js_file).to be_attached
        expect(mlx42_block.data_file).not_to be_attached
      end

      it "does not attach JS file if it does not exist" do
        File.delete(js_path)

        service.compile

        mlx42_block.reload
        expect(mlx42_block.wasm_file).to be_attached
        expect(mlx42_block.js_file).not_to be_attached
      end
    end

    context "with compilation failure" do
      before do
        allow(Open3).to receive(:capture3).and_return(
          [ "stdout output", "compilation error message", double(success?: false) ]
        )
      end

      it "returns failure result" do
        result = service.compile

        expect(result[:success]).to be false
        expect(result[:error]).to include("Compilation failed")
      end

      it "includes stderr in error message" do
        result = service.compile

        expect(result[:error]).to include("compilation error message")
      end

      it "includes stdout in error message" do
        result = service.compile

        expect(result[:error]).to include("stdout output")
      end

      it "sets compilation error on block" do
        service.compile

        expect(mlx42_block.compilation_error).to include("compilation error message")
      end

      it "saves the block with error" do
        expect(mlx42_block).to receive(:save!).at_least(:once)

        service.compile
      end
    end

    context "with exception during compilation" do
      before do
        allow(Open3).to receive(:capture3).and_raise(StandardError, "emcc not found")
      end

      it "returns failure result" do
        result = service.compile

        expect(result[:success]).to be false
      end

      it "includes exception message in error" do
        result = service.compile

        expect(result[:error]).to include("emcc not found")
      end

      it "sets compilation error on block" do
        service.compile

        expect(mlx42_block.compilation_error).to include("emcc not found")
      end
    end

    context "with custom dimensions" do
      it "substitutes width in wrapper template" do
        mlx42_block.data = mlx42_block.data.merge("width" => 1024)
        mlx42_block.save!

        files_written = {}
        allow(File).to receive(:write).and_wrap_original do |m, path, content|
          files_written[path] = content
          m.call(path, content)
        end

        allow(Open3).to receive(:capture3).and_return([ "", "", double(success?: false) ])

        service.compile

        wrapper_content = files_written.values.find { |c| c.include?("mlx_t *mlx") }
        expect(wrapper_content).to include("WIDTH 1024")
      end

      it "substitutes height in wrapper template" do
        mlx42_block.data = mlx42_block.data.merge("height" => 768)
        mlx42_block.save!

        files_written = {}
        allow(File).to receive(:write).and_wrap_original do |m, path, content|
          files_written[path] = content
          m.call(path, content)
        end

        allow(Open3).to receive(:capture3).and_return([ "", "", double(success?: false) ])

        service.compile

        wrapper_content = files_written.values.find { |c| c.include?("mlx_t *mlx") }
        expect(wrapper_content).to include("HEIGHT 768")
      end
    end

    context "with custom compiler arguments" do
      it "includes custom compiler args in command" do
        mlx42_block.data = mlx42_block.data.merge("compiler_args" => "-O2 -Wall")
        mlx42_block.save!

        allow(Open3).to receive(:capture3) do |command|
          expect(command).to include("-O2")
          expect(command).to include("-Wall")
          [ "", "", double(success?: false) ]
        end

        service.compile
      end

      it "handles empty compiler args" do
        mlx42_block.data = mlx42_block.data.merge("compiler_args" => "")
        mlx42_block.save!

        allow(Open3).to receive(:capture3).and_return(
          [ "", "", double(success?: false) ]
        )

        expect { service.compile }.not_to raise_error
      end
    end

    context "with assets" do
      before do
        mlx42_block.assets.attach(
          io: StringIO.new("fake asset content"),
          filename: "texture.png",
          content_type: "image/png"
        )
      end

      it "creates assets directory during compilation" do
        created_dirs = []
        allow(Dir).to receive(:mkdir).and_wrap_original do |m, *args|
          created_dirs << args[0]
          m.call(*args)
        end

        allow(Open3).to receive(:capture3).and_return([ "", "", double(success?: false) ])

        service.compile

        expect(created_dirs.any? { |dir| dir.end_with?("/assets") }).to be true
      end

      it "copies assets to directory" do
        asset_files_created = []
        allow(File).to receive(:open).and_wrap_original do |m, *args, &block|
          asset_files_created << args[0] if args[0].to_s.include?("assets/texture.png")
          m.call(*args, &block)
        end

        allow(Open3).to receive(:capture3).and_return([ "", "", double(success?: false) ])

        service.compile

        expect(asset_files_created).not_to be_empty
      end

      it "includes preload-file argument for assets" do
        captured_command = nil
        allow(Open3).to receive(:capture3) do |command|
          captured_command = command
          [ "", "", double(success?: false) ]
        end

        service.compile

        expect(captured_command).to include("--preload-file")
        expect(captured_command).to match(/\/assets/)
      end
    end

    context "with file creation" do
      it "creates user code file" do
        files_written = {}
        allow(File).to receive(:write).and_wrap_original do |m, path, content|
          files_written[path] = content
          m.call(path, content)
        end

        allow(Open3).to receive(:capture3).and_return([ "", "", double(success?: false) ])

        service.compile

        user_file = files_written.keys.find { |k| k.end_with?("user_code.c") }
        expect(user_file).to be_present
        expect(files_written[user_file]).to eq(mlx42_block.text)
      end

      it "creates wrapper file with template" do
        files_written = {}
        allow(File).to receive(:write).and_wrap_original do |m, path, content|
          files_written[path] = content
          m.call(path, content)
        end

        allow(Open3).to receive(:capture3).and_return([ "", "", double(success?: false) ])

        service.compile

        wrapper_file = files_written.keys.find { |k| k.end_with?("wrapper_main.c") }
        expect(wrapper_file).to be_present
        expect(files_written[wrapper_file]).to include("mlx_t *mlx")
      end

      it "uses temporary directory" do
        expect(Dir).to receive(:mktmpdir).and_call_original

        allow(Open3).to receive(:capture3).and_return([ "", "", double(success?: false) ])

        service.compile
      end

      it "cleans up temporary directory after completion" do
        temp_dir = nil

        allow(Dir).to receive(:mktmpdir).and_wrap_original do |m, &block|
          m.call do |dir|
            temp_dir = dir
            block.call(dir)
          end
        end

        allow(Open3).to receive(:capture3).and_return([ "", "", double(success?: false) ])

        service.compile

        expect(File.exist?(temp_dir)).to be false
      end
    end

    context "compile command construction" do
      it "includes emcc compiler" do
        allow(Open3).to receive(:capture3) do |command|
          expect(command).to include("emcc")
          [ "", "", double(success?: false) ]
        end

        service.compile
      end

      it "includes MLX42 library path" do
        allow(Open3).to receive(:capture3) do |command|
          expect(command).to include("libmlx42_web.a")
          [ "", "", double(success?: false) ]
        end

        service.compile
      end

      it "includes WebGL and WASM settings" do
        allow(Open3).to receive(:capture3) do |command|
          expect(command).to include("USE_GLFW=3")
          expect(command).to include("USE_WEBGL2=1")
          expect(command).to include("WASM=1")
          [ "", "", double(success?: false) ]
        end

        service.compile
      end

      it "includes modularize and export name" do
        allow(Open3).to receive(:capture3) do |command|
          expect(command).to include("MODULARIZE=1")
          expect(command).to include("createMlx42Module")
          [ "", "", double(success?: false) ]
        end

        service.compile
      end

      it "includes memory growth setting" do
        allow(Open3).to receive(:capture3) do |command|
          expect(command).to include("ALLOW_MEMORY_GROWTH")
          [ "", "", double(success?: false) ]
        end

        service.compile
      end
    end
  end

  describe "WRAPPER_TEMPLATE" do
    it "includes MLX42 headers" do
      expect(described_class::WRAPPER_TEMPLATE).to include("#include <MLX42/MLX42.h>")
      expect(described_class::WRAPPER_TEMPLATE).to include("#include <emscripten.h>")
    end

    it "includes WIDTH and HEIGHT defines" do
      expect(described_class::WRAPPER_TEMPLATE).to include("#define WIDTH %{width}")
      expect(described_class::WRAPPER_TEMPLATE).to include("#define HEIGHT %{height}")
    end

    it "declares extern user_main function" do
      expect(described_class::WRAPPER_TEMPLATE).to include("extern void user_main(int argc, char **argv)")
    end

    it "includes mlx initialization" do
      expect(described_class::WRAPPER_TEMPLATE).to include("mlx_init")
    end

    it "includes emscripten main loop" do
      expect(described_class::WRAPPER_TEMPLATE).to include("emscripten_set_main_loop")
    end
  end
end
