require "rails_helper"

RSpec.describe Comment, type: :model do
  it { should belong_to(:commentable) }
  it { should validate_presence_of(:body_markdown) }
  it { should validate_inclusion_of(:status).in_array(%w[visible pending hidden]) }

  it "increments counter caches" do
    doc = create(:document)
    expect {
      create(:comment, commentable: doc, actor_hash: "a1")
    }.to change { doc.reload.comments_count }.by(1)
  end
end
