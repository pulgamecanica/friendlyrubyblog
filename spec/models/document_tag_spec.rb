# spec/models/document_tag_spec.rb
require "rails_helper"

RSpec.describe DocumentTag, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:document) }
    it { is_expected.to belong_to(:tag) }
  end

  describe "database constraints" do
    let(:doc) { create(:document) }
    let(:tag) { create(:tag) }

    before { create(:document_tag, document: doc, tag: tag) }

    it "rejects duplicates at the model level" do
      dup = described_class.new(document: doc, tag: tag)
      expect { dup.save! }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "rejects duplicates at the DB level (unique index) even if validations are skipped" do
      dup = described_class.new(document: doc, tag: tag)
      expect { dup.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
