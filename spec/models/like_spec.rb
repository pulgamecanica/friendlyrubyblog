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
end
