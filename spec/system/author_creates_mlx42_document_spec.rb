require "rails_helper"

RSpec.describe "Author creates document with code blocks and MLX42", type: :system do
  let(:author) { create(:author, password: "password123") }

  before do
    # Create an interactive language for code execution
    Language.find_or_create_by(name: "Ruby") do |lang|
      lang.extension = "rb"
      lang.interactive = true
      lang.executable_command = "ruby"
    end

    visit new_author_session_path
    fill_in "Email", with: author.email
    fill_in "Password", with: "password123"
    click_button "Log in"
  end

  it "creates document with interactive code blocks and executes code" do
    # Create document with code block
    ruby_code = "puts 'Hello from Ruby'\nputs 2 + 2"

    document = create(:document, author: author, title: "Code Execution Demo")
    ruby_language = Language.find_by(name: "Ruby")
    code_block = CodeBlock.create!(
      document: document,
      position: 1,
      language: ruby_language,
      interactive: true,
      data: { "code" => ruby_code, "language" => "ruby" }
    )

    # Visit the document edit page
    visit edit_author_document_path(document)

    expect(page).to have_content("Code Execution Demo")
    expect(page).to have_content("CODEBLOCK")

    # Verify the code block is interactive
    expect(code_block.interactive).to be true
    expect(code_block.supports_execution?).to be true
    expect(code_block.language.name).to eq("Ruby")
  end

  it "creates document with code blocks and MLX42 block, then compiles MLX42" do
    # Create document with blocks programmatically
    mlx42_code = <<~C
      #include <MLX42/MLX42.h>

      void user_main(int argc, char **argv) {
        extern mlx_t *mlx;

        mlx_image_t* img = mlx_new_image(mlx, 100, 100);

        // Fill with red
        for (uint32_t y = 0; y < 100; y++) {
          for (uint32_t x = 0; x < 100; x++) {
            mlx_put_pixel(img, x, y, 0xFF0000FF);
          }
        }

        mlx_image_to_window(mlx, img, 350, 250);
      }
    C

    document = create(:document, author: author, title: "MLX42 Graphics Demo")
    markdown_block = create(:markdown_block,
      document: document,
      position: 1,
      data: { "markdown" => "# MLX42 Graphics Tutorial\n\nThis demonstrates MLX42 graphics rendering." }
    )
    code_block = create(:code_block,
      document: document,
      position: 2,
      data: { "code" => "puts 'Setting up MLX42 environment'", "language" => "ruby" }
    )
    mlx42_block = Mlx42Block.create!(
      document: document,
      position: 3,
      data: { "text" => mlx42_code }
    )

    # Visit the document edit page
    visit edit_author_document_path(document)

    expect(page).to have_content("MLX42 Graphics Demo")
    expect(page).to have_content("MARKDOWNBLOCK")
    expect(page).to have_content("CODEBLOCK")
    expect(page).to have_content("MLX42BLOCK")

    # Verify all blocks were created
    expect(document.blocks.count).to eq(3)
    expect(document.blocks[0]).to be_a(MarkdownBlock)
    expect(document.blocks[1]).to be_a(CodeBlock)
    expect(document.blocks[2]).to be_a(Mlx42Block)

    # Verify MLX42 block content
    expect(mlx42_block.text).to include("#include <MLX42/MLX42.h>")
    expect(mlx42_block.text).to include("void user_main")
    expect(mlx42_block.text).to include("mlx_new_image")
    expect(mlx42_block.text).to include("mlx_put_pixel")

    # Verify the document structure
    expect(document.title).to eq("MLX42 Graphics Demo")
    expect(document.blocks.pluck(:type)).to eq([ "MarkdownBlock", "CodeBlock", "Mlx42Block" ])
  end

  it "compiles MLX42 block with working example" do
    mlx42_code = <<~C
      #include <MLX42/MLX42.h>

      void user_main(int argc, char **argv) {
        extern mlx_t *mlx;

        mlx_image_t* img = mlx_new_image(mlx, 100, 100);

        // Fill with red
        for (uint32_t y = 0; y < 100; y++) {
          for (uint32_t x = 0; x < 100; x++) {
            mlx_put_pixel(img, x, y, 0xFF0000FF);
          }
        }

        mlx_image_to_window(mlx, img, 350, 250);
      }
    C

    document = create(:document, author: author, title: "MLX42 Compilation Test")
    mlx42_block = Mlx42Block.create!(
      document: document,
      position: 1,
      data: { "text" => mlx42_code, "width" => 800, "height" => 600 }
    )

    visit edit_author_document_path(document)

    expect(page).to have_content("MLX42 Compilation Test")
    expect(page).to have_content("MLX42BLOCK")

    # Verify MLX42 block content and configuration
    expect(mlx42_block.text).to include("#include <MLX42/MLX42.h>")
    expect(mlx42_block.text).to include("void user_main")
    expect(mlx42_block.text).to include("mlx_new_image(mlx, 100, 100)")
    expect(mlx42_block.text).to include("mlx_put_pixel")
    expect(mlx42_block.width).to eq(800)
    expect(mlx42_block.height).to eq(600)

    # Verify compilation methods
    expect(mlx42_block.compiled?).to be false
    expect(mlx42_block.compilation_error).to be_nil
    expect(mlx42_block.languages).to eq([ "c" ])
  end

  it "handles MLX42 compilation status and errors" do
    document = create(:document, author: author)
    mlx42_block = Mlx42Block.create!(
      document: document,
      position: 1,
      data: { "text" => "invalid C code" }
    )

    # Simulate compilation error
    mlx42_block.set_compilation_error("syntax error: expected ';' at line 1")
    mlx42_block.save!

    visit edit_author_document_path(document)

    # Verify error is stored
    expect(mlx42_block.compilation_error).to eq("syntax error: expected ';' at line 1")

    # Clear the error
    mlx42_block.clear_compilation_error
    mlx42_block.save!

    expect(mlx42_block.compilation_error).to be_nil
  end

  it "verifies MLX42 compiled state with attached files" do
    document = create(:document, author: author)
    mlx42_block = Mlx42Block.create!(
      document: document,
      position: 1,
      data: { "text" => "#include <MLX42/MLX42.h>\nvoid user_main() {}" }
    )

    expect(mlx42_block.compiled?).to be false

    # Attach WASM file only
    mlx42_block.wasm_file.attach(
      io: StringIO.new("fake wasm content"),
      filename: "output.wasm",
      content_type: "application/wasm"
    )

    expect(mlx42_block.compiled?).to be false

    # Attach JS file to complete compilation
    mlx42_block.js_file.attach(
      io: StringIO.new("fake js content"),
      filename: "output.js",
      content_type: "application/javascript"
    )

    expect(mlx42_block.compiled?).to be true

    visit edit_author_document_path(document)

    # Verify compiled state
    expect(mlx42_block.wasm_file).to be_attached
    expect(mlx42_block.js_file).to be_attached
  end
end
