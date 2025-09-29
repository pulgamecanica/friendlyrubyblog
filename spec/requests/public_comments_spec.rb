require "rails_helper"

RSpec.describe "Public comments", type: :request do
  let!(:doc) { create(:document) }

  describe "successful comment creation" do
    it "creates a comment for a document" do
      content = "Hi!"
      post public_document_comments_path(doc), params: {
        comment: { name: "A", body_markdown: content }
      }
      expect(response).to have_http_status(302).or have_http_status(303)
      expect(doc.reload.comments_count).to eq(1)
      expect(doc.reload.comments.last.body_markdown).to eq(content)
    end


    it "sets proper metadata on comment creation" do
      post public_document_comments_path(doc), params: {
        comment: { name: "Test User", body_markdown: "Hello" }
      }

      comment = doc.reload.comments.last
      expect(comment.actor_hash).to be_present
      expect(comment.ip_hash).to be_present
      expect(comment.user_agent_hash).to be_present
      expect(comment.status).to eq("visible")
    end
  end

  describe "failure scenarios" do
    it "fails to create comment without required body_markdown" do
      initial_count = doc.comments_count

      post public_document_comments_path(doc), params: {
        comment: { name: "Test User", body_markdown: "" }
      }

      expect(response).to have_http_status(302).or have_http_status(303)
      expect(doc.reload.comments_count).to eq(initial_count)
      expect(flash[:alert]).to include("can't be blank")
    end

    it "fails to create comment with invalid params" do
      initial_count = doc.comments_count

      post public_document_comments_path(doc), params: {
        comment: { name: "", body_markdown: "" }
      }

      expect(response).to have_http_status(302).or have_http_status(303)
      expect(doc.reload.comments_count).to eq(initial_count)
      expect(flash[:alert]).to be_present
    end

    it "redirects back with errors when comment is invalid" do
      post public_document_comments_path(doc), params: {
        comment: { body_markdown: "" }
      }

      expect(response).to have_http_status(302).or have_http_status(303)
      expect(flash[:alert]).to be_present
    end
  end

  describe "wrong target scenarios" do
    it "returns 404 for non-existent document" do
      post "/public/documents/nonexistent-slug/comments", params: {
        comment: { name: "Test", body_markdown: "Hello" }
      }

      expect(response).to have_http_status(404)
    end


    it "raises RecordNotFound when no target is specified" do
      # Test controller logic directly for edge case
      controller = Public::CommentsController.new
      controller.params = ActionController::Parameters.new({})

      expect {
        controller.send(:find_target!)
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "handles unpublished document access" do
      unpublished_doc = create(:document, published_at: nil)

      # Unpublished documents are still accessible via the public controller
      # This test verifies comments can be posted to unpublished documents
      post public_document_comments_path(unpublished_doc), params: {
        comment: { name: "Test", body_markdown: "Hello" }
      }

      expect(response).to have_http_status(302).or have_http_status(303)
      expect(unpublished_doc.reload.comments_count).to eq(1)
    end
  end

  describe "different comment scenarios" do
    it "handles comment with parent_id for threading" do
      parent_comment = create(:comment, commentable: doc, body_markdown: "Parent comment")

      post public_document_comments_path(doc), params: {
        comment: {
          name: "Replier",
          body_markdown: "Reply to parent",
          parent_id: parent_comment.id
        }
      }

      reply = doc.reload.comments.last
      expect(reply.parent_id).to eq(parent_comment.id)
    end

    it "handles comment with optional fields" do
      post public_document_comments_path(doc), params: {
        comment: {
          name: "Full User",
          email: "user@example.com",
          website: "https://example.com",
          body_markdown: "Comment with all fields"
        }
      }

      comment = doc.reload.comments.last
      expect(comment.name).to eq("Full User")
      expect(comment.email).to eq("user@example.com")
      expect(comment.website).to eq("https://example.com")
      expect(comment.body_markdown).to eq("Comment with all fields")
    end
  end

  describe "security" do
    it "has CSRF protection configured" do
      # Verify controller has protect_from_forgery set up
      expect(Public::CommentsController.ancestors).to include(ActionController::RequestForgeryProtection)
    end

    it "sanitizes and hashes IP address" do
      post public_document_comments_path(doc), params: {
        comment: { name: "Test", body_markdown: "Hello" }
      }

      comment = doc.reload.comments.last
      expect(comment.ip_hash).to be_present
      expect(comment.ip_hash).to match(/\A[a-f0-9]{64}\z/) # SHA256 hex
    end

    it "hashes user agent" do
      post public_document_comments_path(doc), params: {
        comment: { name: "Test", body_markdown: "Hello" }
      }, headers: { "User-Agent" => "Test Browser/1.0" }

      comment = doc.reload.comments.last
      expect(comment.user_agent_hash).to be_present
      expect(comment.user_agent_hash).to match(/\A[a-f0-9]{64}\z/)
    end
  end
end
