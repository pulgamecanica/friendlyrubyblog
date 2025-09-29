# spec/models/tag_spec.rb
require "rails_helper"

RSpec.describe Tag, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:document_tags).dependent(:destroy) }
    it { is_expected.to have_many(:documents).through(:document_tags) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:slug) }
  end

  describe "factories / basic validity" do
    it "is valid with title and slug" do
      tag = build(:tag, title: "Ruby", slug: "ruby")
      expect(tag).to be_valid
    end
  end
end
