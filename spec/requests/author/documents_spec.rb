require 'rails_helper'

RSpec.describe "Author::Documents", type: :request do
  let(:author) { create(:author) }

  before do
    sign_in author, scope: :author
  end

  describe "GET /author/documents" do
    it "returns successful response" do
      get author_documents_path
      expect(response).to have_http_status(:ok)
    end

    it "displays recent documents regardless of author" do
      doc1 = create(:document, author: author, title: "My Document")
      doc2 = create(:document, title: "Other Author Document") # different author

      get author_documents_path

      expect(response.body).to include("My Document")
      expect(response.body).to include("Other Author Document")
    end

    it "shows published and draft documents" do
      create(:document, author: author, title: "Published", published_at: 1.day.ago)
      create(:document, author: author, title: "Draft", published_at: nil)

      get author_documents_path

      expect(response.body).to include("Published")
      expect(response.body).to include("Draft")
    end
  end

  describe "GET /author/documents/:id" do
    let(:document) { create(:document, author: author) }

    it "shows any document" do
      get author_document_path(document)
      expect(response).to have_http_status(:ok)
    end

    it "allows access to other author's documents" do
      other_document = create(:document, title: "Other Doc")
      get author_document_path(other_document)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /author/documents/new" do
    it "shows new document form" do
      get new_author_document_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("New Document")
    end
  end

  describe "POST /author/documents" do
    let(:valid_params) do
      {
        document: {
          title: "New Document",
          description: "Test description",
          kind: "post"
        }
      }
    end

    it "creates document with valid params" do
      expect {
        post author_documents_path, params: valid_params
      }.to change(Document, :count).by(1)

      document = Document.last
      expect(document.title).to eq("New Document")
      expect(document.author).to eq(author)
      expect(response).to redirect_to(edit_author_document_path(document))
    end

    it "creates document as draft regardless of published parameter" do
      params = valid_params.deep_merge(document: { published: "1" })

      post author_documents_path, params: params

      document = Document.last
      expect(document.published_at).to be_nil
      expect(document.published).to be_falsey
    end

    it "creates document as draft when published not checked" do
      post author_documents_path, params: valid_params

      document = Document.last
      expect(document.published_at).to be_nil
      expect(document.published).to be_falsey
    end

    it "assigns uncategorized series when none provided" do
      post author_documents_path, params: valid_params

      document = Document.last
      expect(document.series.slug).to eq("uncategorized")
    end
  end

  describe "GET /author/documents/:id/edit" do
    let(:document) { create(:document, author: author) }

    it "shows edit form for any document" do
      get edit_author_document_path(document)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(document.title)
    end

    it "allows editing other author's documents" do
      other_document = create(:document)
      get edit_author_document_path(other_document)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /author/documents/:id" do
    let(:document) { create(:document, author: author, title: "Original Title") }

    let(:valid_params) do
      {
        document: {
          title: "Updated Title",
          description: "Updated description"
        }
      }
    end

    it "updates document with valid params" do
      patch author_document_path(document), params: valid_params

      document.reload
      expect(document.title).to eq("Updated Title")
      expect(document.description).to eq("Updated description")
      expect(response).to redirect_to(edit_author_document_path(document))
    end
  end

  describe "PATCH /author/documents/:id/publish" do
    let(:draft_document) { create(:document, author: author, published_at: nil, published: false) }

    it "publishes a draft document" do
      patch publish_author_document_path(draft_document)

      draft_document.reload
      expect(draft_document.published_at).to be_present
      expect(draft_document.published).to be true
      expect(response).to redirect_to(author_documents_path)
    end

    it "shows flash message on successful publish" do
      patch publish_author_document_path(draft_document)
      follow_redirect!
      expect(response.body).to include("Published")
    end

    it "allows publishing other author's documents" do
      other_document = create(:document, published_at: nil, published: false)
      patch publish_author_document_path(other_document)
      expect(response).to redirect_to(author_documents_path)
    end
  end

  describe "PATCH /author/documents/:id/unpublish" do
    let(:published_document) { create(:document, author: author, published_at: 1.day.ago, published: true) }

    it "unpublishes a published document" do
      patch unpublish_author_document_path(published_document)

      published_document.reload
      expect(published_document.published).to be false
      expect(response).to redirect_to(author_documents_path)
    end

    it "shows flash message on successful unpublish" do
      patch unpublish_author_document_path(published_document)
      follow_redirect!
      expect(response.body).to include("Unpublished")
    end

    it "allows unpublishing other author's documents" do
      other_document = create(:document, published_at: 1.day.ago, published: true)
      patch unpublish_author_document_path(other_document)
      expect(response).to redirect_to(author_documents_path)
    end
  end

  describe "DELETE /author/documents/:id" do
    let!(:document) { create(:document, author: author) }

    it "destroys any document" do
      expect {
        delete author_document_path(document)
      }.to change(Document, :count).by(-1)

      expect(response).to redirect_to(author_documents_path)
    end

    it "allows deleting other author's documents" do
      other_document = create(:document)

      expect {
        delete author_document_path(other_document)
      }.to change(Document, :count).by(-1)
    end
  end

  describe "authentication" do
    before do
      sign_out author
    end

    it "redirects to login for index" do
      get author_documents_path
      expect(response).to redirect_to(new_author_session_path)
    end

    it "redirects to login for show" do
      document = create(:document, author: author)
      get author_document_path(document)
      expect(response).to redirect_to(new_author_session_path)
    end

    it "redirects to login for create" do
      post author_documents_path, params: { document: { title: "Test" } }
      expect(response).to redirect_to(new_author_session_path)
    end

    it "redirects to login for publish" do
      document = create(:document, author: author)
      patch publish_author_document_path(document)
      expect(response).to redirect_to(new_author_session_path)
    end
  end

  describe "DELETE /author/documents/:document_id/blocks/:id" do
    it "deletes a block from the document and redirects back to edit" do
      document = create(:document, author: author)
      block = Block.create!(document: document, type: "MarkdownBlock", position: 1, data: { "markdown" => "Hello" })

      expect {
        delete author_document_block_path(document, block)
      }.to change(Block, :count).by(-1)

      expect(response).to redirect_to(edit_author_document_path(document))
    end
  end

  describe "POST /author/documents/:document_id/blocks/preview" do
    it "renders HTML preview of provided markdown" do
      document = create(:document, author: author)

      post preview_author_document_blocks_path(document), params: { markdown: "**hey**" }

      expect(response).to have_http_status(:ok)
      # avoid being brittle about wrapping tags; check for strong text presence
      expect(response.body).to include("<strong>hey</strong>")
    end
  end
end
