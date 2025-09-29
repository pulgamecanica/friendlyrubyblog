require 'rails_helper'

RSpec.describe Author, type: :model do
  it { should have_many(:documents).dependent(:nullify) }
  it { should validate_presence_of(:email) }
  it { should validate_uniqueness_of(:email).case_insensitive }

  describe "#name" do
    it "returns email prefix as name" do
      author = create(:author, email: "john.doe@example.com")
      expect(author.name).to eq("john.doe")
    end

    it "handles simple email addresses" do
      author = create(:author, email: "jane@test.com")
      expect(author.name).to eq("jane")
    end
  end
end
