require 'rails_helper'

RSpec.describe Mlx42Block, type: :model do
  describe "#text" do
    it "returns text from data hash" do
      block = Mlx42Block.create!(
        document: create(:document),
        position: 1,
        data: { "text" => "#include <MLX42/MLX42.h>\nvoid user_main() {}" }
      )

      expect(block.text).to eq("#include <MLX42/MLX42.h>\nvoid user_main() {}")
    end
  end

  describe "#text=" do
    it "sets text in data hash" do
      block = Mlx42Block.create!(
        document: create(:document),
        position: 1,
        data: {}
      )

      block.text = "int main() { return 0; }"

      expect(block.data["text"]).to eq("int main() { return 0; }")
    end
  end

  describe "#plain_text" do
    it "returns text content" do
      block = Mlx42Block.create!(
        document: create(:document),
        position: 1,
        data: { "text" => "sample code" }
      )

      expect(block.plain_text).to eq("sample code")
    end
  end

  describe "#languages" do
    it "returns c language" do
      block = Mlx42Block.create!(
        document: create(:document),
        position: 1,
        data: {}
      )

      expect(block.languages).to eq([ "c" ])
    end
  end

  describe "#width" do
    it "returns custom width from data" do
      block = Mlx42Block.create!(
        document: create(:document),
        position: 1,
        data: { "width" => 1024 }
      )

      expect(block.width).to eq(1024)
    end

    it "returns default width of 800" do
      block = Mlx42Block.create!(
        document: create(:document),
        position: 1,
        data: {}
      )

      expect(block.width).to eq(800)
    end
  end

  describe "#height" do
    it "returns custom height from data" do
      block = Mlx42Block.create!(
        document: create(:document),
        position: 1,
        data: { "height" => 768 }
      )

      expect(block.height).to eq(768)
    end

    it "returns default height of 600" do
      block = Mlx42Block.create!(
        document: create(:document),
        position: 1,
        data: {}
      )

      expect(block.height).to eq(600)
    end
  end

  describe "#compiler_args" do
    it "returns compiler args from data" do
      block = Mlx42Block.create!(
        document: create(:document),
        position: 1,
        data: { "compiler_args" => "-O2 -Wall" }
      )

      expect(block.compiler_args).to eq("-O2 -Wall")
    end

    it "returns empty string when not set" do
      block = Mlx42Block.create!(
        document: create(:document),
        position: 1,
        data: {}
      )

      expect(block.compiler_args).to eq("")
    end
  end

  describe "#compiled?" do
    it "returns true when both wasm and js files attached" do
      block = Mlx42Block.create!(
        document: create(:document),
        position: 1,
        data: {}
      )

      block.wasm_file.attach(
        io: StringIO.new("fake wasm"),
        filename: "output.wasm",
        content_type: "application/wasm"
      )
      block.js_file.attach(
        io: StringIO.new("fake js"),
        filename: "output.js",
        content_type: "application/javascript"
      )

      expect(block.compiled?).to be true
    end

    it "returns false when only wasm file attached" do
      block = Mlx42Block.create!(
        document: create(:document),
        position: 1,
        data: {}
      )

      block.wasm_file.attach(
        io: StringIO.new("fake wasm"),
        filename: "output.wasm",
        content_type: "application/wasm"
      )

      expect(block.compiled?).to be false
    end

    it "returns false when no files attached" do
      block = Mlx42Block.create!(
        document: create(:document),
        position: 1,
        data: {}
      )

      expect(block.compiled?).to be false
    end
  end

  describe "#compilation_error" do
    it "returns compilation error from data" do
      block = Mlx42Block.create!(
        document: create(:document),
        position: 1,
        data: { "compilation_error" => "syntax error on line 5" }
      )

      expect(block.compilation_error).to eq("syntax error on line 5")
    end

    it "returns nil when no error" do
      block = Mlx42Block.create!(
        document: create(:document),
        position: 1,
        data: {}
      )

      expect(block.compilation_error).to be_nil
    end
  end

  describe "#set_compilation_error" do
    it "stores compilation error in data" do
      block = Mlx42Block.create!(
        document: create(:document),
        position: 1,
        data: {}
      )

      block.set_compilation_error("compilation failed")

      expect(block.data["compilation_error"]).to eq("compilation failed")
    end
  end

  describe "#clear_compilation_error" do
    it "removes compilation error from data" do
      block = Mlx42Block.create!(
        document: create(:document),
        position: 1,
        data: { "compilation_error" => "some error" }
      )

      block.clear_compilation_error

      expect(block.data["compilation_error"]).to be_nil
    end
  end

  describe "Active Storage attachments" do
    it "supports wasm_file attachment" do
      block = Mlx42Block.create!(
        document: create(:document),
        position: 1,
        data: {}
      )

      block.wasm_file.attach(
        io: StringIO.new("wasm content"),
        filename: "program.wasm",
        content_type: "application/wasm"
      )

      expect(block.wasm_file).to be_attached
    end

    it "supports js_file attachment" do
      block = Mlx42Block.create!(
        document: create(:document),
        position: 1,
        data: {}
      )

      block.js_file.attach(
        io: StringIO.new("js content"),
        filename: "program.js",
        content_type: "application/javascript"
      )

      expect(block.js_file).to be_attached
    end

    it "supports data_file attachment" do
      block = Mlx42Block.create!(
        document: create(:document),
        position: 1,
        data: {}
      )

      block.data_file.attach(
        io: StringIO.new("data content"),
        filename: "program.data",
        content_type: "application/octet-stream"
      )

      expect(block.data_file).to be_attached
    end

    it "supports multiple assets attachments" do
      block = Mlx42Block.create!(
        document: create(:document),
        position: 1,
        data: {}
      )

      block.assets.attach(
        io: StringIO.new("asset 1"),
        filename: "texture.png",
        content_type: "image/png"
      )
      block.assets.attach(
        io: StringIO.new("asset 2"),
        filename: "sound.wav",
        content_type: "audio/wav"
      )

      expect(block.assets.count).to eq(2)
    end
  end
end
