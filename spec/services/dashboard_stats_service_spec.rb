require 'rails_helper'

RSpec.describe DashboardStatsService do
  let(:author) { create(:author) }
  let(:other_author) { create(:author) }
  let(:service) { described_class.new(author) }
  let(:global_service) { described_class.new }

  describe "#recent_views" do
    it "returns recent views for author's documents ordered by visited_at desc" do
      doc1 = create(:document, author: author)
      doc2 = create(:document, author: author)
      other_doc = create(:document, author: other_author)

      view1 = create(:page_view, document: doc1, visited_at: 1.day.ago)
      view2 = create(:page_view, document: doc2, visited_at: 2.hours.ago)
      view3 = create(:page_view, document: doc1, visited_at: 1.hour.ago)
      other_view = create(:page_view, document: other_doc, visited_at: 30.minutes.ago)

      results = service.recent_views

      expect(results).to include(view3, view2, view1)
      expect(results).not_to include(other_view)
      expect(results.first).to eq(view3)  # Most recent
    end

    it "limits results to specified number" do
      doc = create(:document, author: author)
      25.times { create(:page_view, document: doc) }

      results = service.recent_views(10)

      expect(results.count).to eq(10)
    end

    it "defaults to 20 results" do
      doc = create(:document, author: author)
      30.times { create(:page_view, document: doc) }

      results = service.recent_views

      expect(results.count).to eq(20)
    end

    it "includes document association" do
      doc = create(:document, author: author)
      view = create(:page_view, document: doc)

      results = service.recent_views

      # Verify document is included (no additional query needed)
      expect(results.first.association(:document).loaded?).to be true
    end
  end

  describe "#views_over_time" do
    it "returns views grouped by date for last 30 days" do
      doc = create(:document, author: author)

      create(:page_view, document: doc, visited_at: 5.days.ago)
      create(:page_view, document: doc, visited_at: 5.days.ago)
      create(:page_view, document: doc, visited_at: 10.days.ago)
      create(:page_view, document: doc, visited_at: 40.days.ago)  # Outside window

      results = service.views_over_time(30)

      date_5_days_ago = 5.days.ago.to_date.to_s
      date_10_days_ago = 10.days.ago.to_date.to_s

      expect(results[date_5_days_ago]).to eq(2)
      expect(results[date_10_days_ago]).to eq(1)
      expect(results.values.sum).to eq(3)  # Doesn't include 40 days ago
    end

    it "returns string keys for dates" do
      doc = create(:document, author: author)
      create(:page_view, document: doc, visited_at: 1.day.ago)

      results = service.views_over_time(7)

      expect(results.keys.first).to be_a(String)
    end

    it "accepts custom days parameter" do
      doc = create(:document, author: author)

      create(:page_view, document: doc, visited_at: 5.days.ago)
      create(:page_view, document: doc, visited_at: 10.days.ago)

      results = service.views_over_time(7)

      expect(results.values.sum).to eq(1)  # Only 5 days ago
    end

    it "only includes author's documents when author specified" do
      author_doc = create(:document, author: author)
      other_doc = create(:document, author: other_author)

      create(:page_view, document: author_doc, visited_at: 1.day.ago)
      create(:page_view, document: other_doc, visited_at: 1.day.ago)

      results = service.views_over_time(30)

      expect(results.values.sum).to eq(1)
    end
  end

  describe "#documents_over_time" do
    it "returns documents grouped by creation date for last 30 days" do
      create(:document, author: author, created_at: 5.days.ago)
      create(:document, author: author, created_at: 5.days.ago)
      create(:document, author: author, created_at: 10.days.ago)
      create(:document, author: author, created_at: 40.days.ago)  # Outside window

      results = service.documents_over_time(30)

      date_5_days_ago = 5.days.ago.to_date.to_s
      date_10_days_ago = 10.days.ago.to_date.to_s

      expect(results[date_5_days_ago]).to eq(2)
      expect(results[date_10_days_ago]).to eq(1)
      expect(results.values.sum).to eq(3)
    end

    it "returns string keys for dates" do
      create(:document, author: author, created_at: 1.day.ago)

      results = service.documents_over_time(7)

      expect(results.keys.first).to be_a(String)
    end

    it "accepts custom days parameter" do
      create(:document, author: author, created_at: 5.days.ago)
      create(:document, author: author, created_at: 10.days.ago)

      results = service.documents_over_time(7)

      expect(results.values.sum).to eq(1)
    end

    it "only includes author's documents when author specified" do
      create(:document, author: author, created_at: 1.day.ago)
      create(:document, author: other_author, created_at: 1.day.ago)

      results = service.documents_over_time(30)

      expect(results.values.sum).to eq(1)
    end
  end

  describe "#blocks_over_time" do
    it "returns blocks grouped by creation date for last 30 days" do
      doc = create(:document, author: author)

      create(:markdown_block, document: doc, created_at: 5.days.ago, position: 1)
      create(:code_block, document: doc, created_at: 5.days.ago, position: 2)
      create(:markdown_block, document: doc, created_at: 10.days.ago, position: 3)
      create(:markdown_block, document: doc, created_at: 40.days.ago, position: 4)  # Outside window

      results = service.blocks_over_time(30)

      date_5_days_ago = 5.days.ago.to_date.to_s
      date_10_days_ago = 10.days.ago.to_date.to_s

      expect(results[date_5_days_ago]).to eq(2)
      expect(results[date_10_days_ago]).to eq(1)
      expect(results.values.sum).to eq(3)
    end

    it "returns string keys for dates" do
      doc = create(:document, author: author)
      create(:markdown_block, document: doc, created_at: 1.day.ago, position: 1)

      results = service.blocks_over_time(7)

      expect(results.keys.first).to be_a(String)
    end

    it "accepts custom days parameter" do
      doc = create(:document, author: author)

      create(:markdown_block, document: doc, created_at: 5.days.ago, position: 1)
      create(:markdown_block, document: doc, created_at: 10.days.ago, position: 2)

      results = service.blocks_over_time(7)

      expect(results.values.sum).to eq(1)
    end

    it "only includes blocks from author's documents when author specified" do
      author_doc = create(:document, author: author)
      other_doc = create(:document, author: other_author)

      create(:markdown_block, document: author_doc, created_at: 1.day.ago, position: 1)
      create(:markdown_block, document: other_doc, created_at: 1.day.ago, position: 1)

      results = service.blocks_over_time(30)

      expect(results.values.sum).to eq(1)
    end
  end
end
