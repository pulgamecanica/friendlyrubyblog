require 'rails_helper'

RSpec.describe Block, type: :model do
  it { should belong_to(:document) }
  it { should have_many(:likes).dependent(:destroy) }

  it { should validate_presence_of(:type) }
  it { should validate_numericality_of(:position).only_integer.is_greater_than_or_equal_to(0) }

  it "validates data must be a hash" do
    block = build(:markdown_block, data: "string")
    expect(block).not_to be_valid
    expect(block.errors[:data]).to include("must be a JSON object")
  end

  it "orders blocks by position by default" do
    document = create(:document)
    block3 = create(:markdown_block, document: document, position: 3)
    block1 = create(:markdown_block, document: document, position: 1)
    block2 = create(:markdown_block, document: document, position: 2)

    expect(document.blocks.pluck(:position)).to eq([ 1, 2, 3 ])
  end

  it "requires position to be a non-negative integer" do
    document = create(:document)

    # Test that nil position is invalid
    block = build(:markdown_block, document: document, position: nil)
    expect(block).not_to be_valid
    expect(block.errors[:position]).to include("is not a number")

    # Test negative position is invalid
    block.position = -1
    expect(block).not_to be_valid
    expect(block.errors[:position]).to include("must be greater than or equal to 0")

    # Test float position is invalid
    block.position = 1.5
    expect(block).not_to be_valid
    expect(block.errors[:position]).to include("must be an integer")
  end

  it "allows setting specific position" do
    document = create(:document)
    block = create(:markdown_block, document: document, position: 5)

    expect(block.position).to eq(5)
  end

  it "allows multiple blocks with same position" do
    document = create(:document)
    block1 = create(:markdown_block, document: document, position: 1)
    block2 = create(:markdown_block, document: document, position: 1)

    expect(block1.position).to eq(1)
    expect(block2.position).to eq(1)
  end

  it "maintains position when updated" do
    document = create(:document)
    block = create(:markdown_block, document: document, position: 2)

    block.update(position: 5)

    expect(block.reload.position).to eq(5)
  end

  it "triggers document search reindex after commit" do
    document = create(:document)

    expect(document).to receive(:reindex_search!)

    create(:markdown_block, document: document)
  end

  describe "subclass behavior" do
    it "MarkdownBlock returns plain text" do
      block = create(:markdown_block, data: { "markdown" => "# Hello **world**" })
      expect(block.plain_text).to include("Hello")
    end

    it "CodeBlock returns language for facet_languages" do
      block = create(:code_block, data: { "language" => "ruby", "code" => "puts 1" })
      expect(block.languages).to include("ruby")
    end

    it "MarkdownBlock extracts languages from fenced code blocks" do
      block = create(:markdown_block, data: {
        "markdown" => "```ruby\nputs 1\n```\n```javascript\nconsole.log(1)\n```"
      })
      expect(block.languages).to include("ruby", "javascript")
    end
  end
end
