require "rails_helper"

RSpec.describe Document, type: :model do
  it { should belong_to(:author) }
  it { should belong_to(:series).optional }
  it { should have_many(:blocks).dependent(:destroy) }
  it { should have_many(:comments).dependent(:destroy) }
  it { should have_many(:likes).dependent(:destroy) }

  it { should validate_inclusion_of(:kind).in_array(%w[post note page]) }

  it "auto-assigns Uncategorized series when none provided" do
    doc = build(:document, series: nil)
    doc.valid?
    expect(doc.series.slug).to eq("uncategorized")
  end

  it "aggregates facet_languages from blocks on reindex" do
    doc = create(:document)
    create(:code_block, document: doc, data: { "language" => "ruby", "code" => "puts 1" })
    doc.reindex_search!
    expect(doc.facet_languages).to include("ruby")
  end

  it "aggregates plain text from MarkdownBlock" do
    doc = create(:document)
    create(:markdown_block, document: doc, data: { "markdown" => "# Hi" })

    doc.reindex_search!

    expect(doc.search_text).to include("Hi")
  end

  it "collects languages from fenced code in MarkdownBlock" do
    doc = create(:document)
    create(:markdown_block, document: doc, data: { "markdown" => <<~MD })
      ```ruby
      puts 1
      ```
    MD

    doc.reindex_search!

    expect(doc.facet_languages).to include("ruby")
  end
end
