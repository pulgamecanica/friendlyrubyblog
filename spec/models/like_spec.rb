require "rails_helper"

RSpec.describe Like, type: :model do
  it { should belong_to(:likable) }
  it { should validate_presence_of(:actor_hash) }

  it "enforces uniqueness per actor per target" do
    doc = create(:document)
    create(:like, likable: doc, actor_hash: "a1")
    dup = build(:like, likable: doc, actor_hash: "a1")
    expect(dup).not_to be_valid
  end

  describe "liking blocks" do
    it "can like a block" do
      block = create(:markdown_block)
      like = create(:like, likable: block, actor_hash: "user123")

      expect(like.likable).to eq(block)
      expect(like.likable_type).to eq("Block")
      expect(like.actor_hash).to eq("user123")
    end

    it "enforces uniqueness per actor per block" do
      block = create(:markdown_block)
      create(:like, likable: block, actor_hash: "user123")
      dup = build(:like, likable: block, actor_hash: "user123")

      expect(dup).not_to be_valid
      expect(dup.errors[:actor_hash]).to include("has already been taken")
    end

    it "allows different actors to like the same block" do
      block = create(:markdown_block)
      like1 = create(:like, likable: block, actor_hash: "user123")
      like2 = create(:like, likable: block, actor_hash: "user456")

      expect(like1).to be_valid
      expect(like2).to be_valid
      expect(block.likes.count).to eq(2)
    end

    it "allows same actor to like different blocks" do
      block1 = create(:markdown_block)
      block2 = create(:code_block)
      like1 = create(:like, likable: block1, actor_hash: "user123")
      like2 = create(:like, likable: block2, actor_hash: "user123")

      expect(like1).to be_valid
      expect(like2).to be_valid
    end

    it "updates likes_count counter cache for blocks" do
      block = create(:markdown_block)
      expect(block.likes_count).to eq(0)

      create(:like, likable: block, actor_hash: "user123")
      block.reload
      expect(block.likes_count).to eq(1)

      create(:like, likable: block, actor_hash: "user456")
      block.reload
      expect(block.likes_count).to eq(2)
    end
  end
end
