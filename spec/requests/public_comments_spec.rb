require "rails_helper"

RSpec.describe "Public comments", type: :request do
  let!(:doc) { create(:document) }

  it "creates a comment for a document" do
    content = "Hi!"
    post public_document_comments_path(doc), params: {
      comment: { name: "A", body_markdown: content }
    }
    expect(response).to have_http_status(302).or have_http_status(303)
    expect(doc.reload.comments_count).to eq(1)
    expect(doc.reload.comments.last.body_markdown).to eq(content)
  end
end
