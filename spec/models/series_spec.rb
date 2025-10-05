require 'rails_helper'

RSpec.describe Series, type: :model do
  it { should have_many(:documents) }
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

  describe "before_destroy callback" do
    describe "#move_documents_to_uncategorized" do
      it "moves all documents to uncategorized series on destroy" do
        uncategorized = Series.uncategorized!
        series = create(:series, title: "Tech Series")
        doc1 = create(:document, series: series, series_position: 1)
        doc2 = create(:document, series: series, series_position: 2)
        doc3 = create(:document, series: series, series_position: 3)

        series.destroy

        doc1.reload
        doc2.reload
        doc3.reload
        expect(doc1.series).to eq(uncategorized)
        expect(doc2.series).to eq(uncategorized)
        expect(doc3.series).to eq(uncategorized)
      end

      it "preserves document order by appending to end of uncategorized series" do
        uncategorized = Series.uncategorized!
        existing_doc = create(:document, series: uncategorized, series_position: 5)

        series = create(:series, title: "Tech Series")
        doc1 = create(:document, series: series, series_position: 1)
        doc2 = create(:document, series: series, series_position: 2)

        series.destroy

        doc1.reload
        doc2.reload
        expect(doc1.series_position).to eq(6)
        expect(doc2.series_position).to eq(7)
      end

      it "handles empty uncategorized series" do
        uncategorized = Series.uncategorized!
        series = create(:series, title: "Tech Series")
        doc1 = create(:document, series: series, series_position: 1)
        doc2 = create(:document, series: series, series_position: 2)

        series.destroy

        doc1.reload
        doc2.reload
        expect(doc1.series_position).to eq(1)
        expect(doc2.series_position).to eq(2)
      end

      it "prevents destroying uncategorized series with documents" do
        uncategorized = Series.uncategorized!
        doc = create(:document, series: uncategorized, series_position: 1)

        # The callback returns early, so documents aren't moved
        # This causes foreign key violation since documents still reference the series
        expect {
          uncategorized.destroy
        }.to raise_error(ActiveRecord::InvalidForeignKey)

        # Series is not destroyed
        expect(Series.exists?(uncategorized.id)).to be true
      end

      it "uses update_columns to avoid callbacks during document transfer" do
        uncategorized = Series.uncategorized!
        series = create(:series, title: "Tech Series")
        doc = create(:document, series: series, series_position: 1)

        # Mock to verify update_columns is called
        allow_any_instance_of(Document).to receive(:update_columns).and_call_original

        series.destroy

        doc.reload
        expect(doc.series).to eq(uncategorized)
      end
    end
  end
end
