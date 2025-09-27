require "rails_helper"

RSpec.describe "Public likes", type: :request do
  let!(:doc) { create(:document) }

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
end
