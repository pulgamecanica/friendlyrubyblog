require 'rails_helper'

RSpec.describe "Author::Blocks", type: :request do
  let(:author) { create(:author) }
  let(:document) { create(:document, author: author) }

  before do
    sign_in author, scope: :author
  end

  describe "POST /author/documents/:document_id/blocks" do
    it "creates a markdown block" do
      expect {
        post author_document_blocks_path(document), params: {
          block: {
            type: "MarkdownBlock",
            data_markdown: "# Hello World"
          }
        }
      }.to change(Block, :count).by(1)

      block = Block.last
      expect(block.type).to eq("MarkdownBlock")
      expect(block.data["markdown"]).to eq("# Hello World")
    end

    it "creates a code block with language" do
      expect {
        post author_document_blocks_path(document), params: {
          block: {
            type: "CodeBlock",
            language_name: "ruby",
            data_code: "puts 'Hello'"
          }
        }
      }.to change(Block, :count).by(1)

      block = CodeBlock.last
      expect(block.data["code"]).to eq("puts 'Hello'")
      expect(block.language.name).to eq("Ruby")
    end
  end

  describe "PATCH /author/documents/:document_id/blocks/:id/toggle_interactive" do
    it "toggles interactive mode for supported code block" do
      language = create(:language, name: "Ruby", extension: "rb", interactive: true)
      block = create(:code_block, document: document, language: language, interactive: false)

      patch toggle_interactive_author_document_block_path(document, block)

      block.reload
      expect(block.interactive).to be true
    end

    it "toggles interactive mode off" do
      language = create(:language, name: "Ruby", extension: "rb", interactive: true)
      block = create(:code_block, document: document, language: language, interactive: true)

      patch toggle_interactive_author_document_block_path(document, block)

      block.reload
      expect(block.interactive).to be false
    end

    it "returns unprocessable entity for non-code block" do
      block = create(:markdown_block, document: document)

      patch toggle_interactive_author_document_block_path(document, block)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns unprocessable entity for non-interactive language" do
      language = create(:language, name: "Text", extension: "txt", interactive: false)
      block = create(:code_block, document: document, language: language)

      patch toggle_interactive_author_document_block_path(document, block)

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "POST /author/documents/:document_id/blocks/:id/execute" do
    it "queues code execution for interactive block" do
      language = create(:language,
        name: "Ruby",
        extension: "rb",
        interactive: true,
        executable_command: "ruby"
      )
      block = create(:code_block,
        document: document,
        language: language,
        interactive: true,
        data: { "code" => "puts 'test'" }
      )

      expect {
        post execute_author_document_block_path(document, block), params: { code: "puts 'Hello'" }
      }.to have_enqueued_job(CodeExecutionJob).with(block.id, "puts 'Hello'")

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["status"]).to eq("queued")
    end

    it "returns error when block does not support execution" do
      block = create(:code_block, document: document, interactive: false)

      post execute_author_document_block_path(document, block), params: { code: "test" }

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json["error"]).to include("does not support code execution")
    end

    it "returns error when no code provided" do
      language = create(:language,
        name: "Ruby",
        interactive: true,
        executable_command: "ruby"
      )
      block = create(:code_block,
        document: document,
        language: language,
        interactive: true
      )

      post execute_author_document_block_path(document, block), params: { code: "" }

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json["error"]).to include("No code provided")
    end
  end

  describe "PATCH /author/documents/:document_id/blocks/sort" do
    it "reorders blocks based on block_ids" do
      block1 = create(:markdown_block, document: document, position: 1)
      block2 = create(:markdown_block, document: document, position: 2)
      block3 = create(:markdown_block, document: document, position: 3)

      patch sort_author_document_blocks_path(document), params: {
        block_ids: [ block3.id, block1.id, block2.id ]
      }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["success"]).to be true

      expect(block3.reload.position).to eq(1)
      expect(block1.reload.position).to eq(2)
      expect(block2.reload.position).to eq(3)
    end

    it "returns error for invalid block_ids parameter" do
      patch sort_author_document_blocks_path(document), params: {
        block_ids: "not an array"
      }

      expect(response).to have_http_status(:bad_request)
      json = JSON.parse(response.body)
      expect(json["success"]).to be false
    end

    it "returns error when block not found" do
      patch sort_author_document_blocks_path(document), params: {
        block_ids: [ 99999 ]
      }

      expect(response).to have_http_status(:not_found)
      json = JSON.parse(response.body)
      expect(json["success"]).to be false
    end
  end

  describe "POST /author/documents/:document_id/blocks/:id/compile_mlx42" do
    it "queues MLX42 compilation" do
      block = Mlx42Block.create!(
        document: document,
        position: 1,
        data: { "text" => "#include <MLX42/MLX42.h>" }
      )

      expect {
        post compile_mlx42_author_document_block_path(document, block)
      }.to have_enqueued_job(Mlx42CompilationJob).with(block.id)

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["status"]).to eq("queued")
      expect(json["message"]).to include("Compilation started")
    end

    it "returns error for non-MLX42 block" do
      block = create(:code_block, document: document)

      post compile_mlx42_author_document_block_path(document, block)

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json["error"]).to include("not an MLX42 block")
    end

    it "sets compilation status to queued" do
      block = Mlx42Block.create!(
        document: document,
        position: 1,
        data: { "text" => "test code" }
      )

      post compile_mlx42_author_document_block_path(document, block)

      block.reload
      expect(block.data["compilation_status"]).to eq("queued")
      expect(block.data["compilation_queued_at"]).to be_present
    end
  end

  describe "PATCH /author/documents/:document_id/blocks/:id" do
    it "updates markdown block data" do
      block = create(:markdown_block, document: document, data: { "markdown" => "Old" })

      patch author_document_block_path(document, block), params: {
        block: {
          data_markdown: "# Updated"
        }
      }

      block.reload
      expect(block.data["markdown"]).to eq("# Updated")
    end

    it "appends images to ImageBlock" do
      block = ImageBlock.create!(document: document, position: 1, data: {})

      expect {
        patch author_document_block_path(document, block), params: {
          block: {
            images: [
              fixture_file_upload(Rails.root.join('spec/fixtures/files/test.jpg'), 'image/jpeg')
            ]
          }
        }
      }.to change { block.images.count }.by(1)
    end

    it "appends assets to Mlx42Block" do
      block = Mlx42Block.create!(document: document, position: 1, data: {})

      expect {
        patch author_document_block_path(document, block), params: {
          block: {
            assets: [
              fixture_file_upload(Rails.root.join('spec/fixtures/files/test.jpg'), 'image/jpeg')
            ]
          }
        }
      }.to change { block.assets.count }.by(1)
    end
  end

  describe "DELETE /author/documents/:document_id/blocks/:id" do
    it "destroys the block" do
      block = create(:markdown_block, document: document)

      expect {
        delete author_document_block_path(document, block)
      }.to change(Block, :count).by(-1)

      expect(response).to have_http_status(:redirect)
    end
  end

  describe "POST /author/documents/:document_id/blocks/preview" do
    it "renders markdown preview" do
      post preview_author_document_blocks_path(document), params: {
        markdown: "**bold text**"
      }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("<strong>bold text</strong>")
    end
  end
end
