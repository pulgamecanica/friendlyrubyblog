require 'rails_helper'

RSpec.describe Series, type: :model do
  it { should have_many(:documents).dependent(:nullify) }
  it { should validate_presence_of(:title) }
  it { should validate_presence_of(:slug) }
  it { should validate_uniqueness_of(:slug) }

  describe ".uncategorized!" do
    it "creates default uncategorized series when none exists" do
      expect(Series.find_by(slug: "uncategorized")).to be_nil

      series = Series.uncategorized!

      expect(series.title).to eq("Uncategorized")
      expect(series.slug).to eq("uncategorized")
      expect(series.description).to be_nil
    end

    it "returns existing uncategorized series when it exists" do
      existing = create(:series, title: "Uncategorized", slug: "uncategorized")

      series = Series.uncategorized!

      expect(series).to eq(existing)
    end
  end

  describe "friendly_id" do
    it "generates slug from title" do
      series = create(:series, title: "My Great Series")
      expect(series.slug).to eq("my-great-series")
    end

    it "regenerates slug when title changes" do
      series = create(:series, title: "Original Title")
      original_slug = series.slug

      series.update(title: "New Title")

      expect(series.slug).not_to eq(original_slug)
      expect(series.slug).to eq("new-title")
    end
  end

  describe "document ordering" do
    it "orders documents by series_position then published_at" do
      series = create(:series)
      doc3 = create(:document, series: series, series_position: 2, published_at: 1.day.ago)
      doc1 = create(:document, series: series, series_position: 1, published_at: 2.days.ago)
      doc2 = create(:document, series: series, series_position: 1, published_at: 1.day.ago)

      expect(series.documents.to_a).to eq([ doc1, doc2, doc3 ])
    end
  end
end
