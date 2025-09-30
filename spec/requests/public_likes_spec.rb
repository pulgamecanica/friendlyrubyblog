require "rails_helper"

RSpec.describe "Public likes", type: :request do
  let!(:doc) { create(:document) }

  describe "document likes" do
    it "likes and unlikes a document (idempotent)" do
      post public_document_like_path(doc)
      expect(response).to be_redirect
      expect(doc.reload.likes_count).to eq(1)

      # repeat (should not increase)
      post public_document_like_path(doc)
      expect(doc.reload.likes_count).to eq(1)

      delete public_document_like_path(doc)
      expect(doc.reload.likes_count).to eq(0)
    end

    it "responds with JSON when requested" do
      post public_document_like_path(doc), headers: { "Accept" => "application/json" }
      expect(response).to have_http_status(:created)
      expect(response.content_type).to match(%r{application/json})

      json = JSON.parse(response.body)
      expect(json["likes_count"]).to eq(1)
    end
  end

  describe "block likes" do
    let!(:block) { create(:markdown_block, document: doc) }

    it "likes and unlikes a block (idempotent)" do
      post public_block_like_path(block)
      expect(response).to be_redirect
      expect(block.reload.likes_count).to eq(1)

      # repeat (should not increase)
      post public_block_like_path(block)
      expect(block.reload.likes_count).to eq(1)

      delete public_block_like_path(block)
      expect(block.reload.likes_count).to eq(0)
    end

    it "responds with JSON when requested" do
      post public_block_like_path(block), headers: { "Accept" => "application/json" }
      expect(response).to have_http_status(:created)
      expect(response.content_type).to match(%r{application/json})

      json = JSON.parse(response.body)
      expect(json["likes_count"]).to eq(1)
    end

    it "redirects to document when liking block via HTML" do
      post public_block_like_path(block)
      expect(response).to redirect_to(public_document_path(doc))
    end

    it "handles invalid block gracefully" do
      post "/blocks/99999/like"
      expect(response).to have_http_status(:not_found)
    end
  end
end
