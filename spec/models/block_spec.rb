require 'rails_helper'

RSpec.describe Block, type: :model do
  it { should belong_to(:document) }
  it { should have_many(:likes).dependent(:destroy) }

  it { should validate_presence_of(:type) }
  it { should validate_numericality_of(:position).only_integer.is_greater_than_or_equal_to(1) }

  it "validates data must be a hash" do
    block = build(:markdown_block, data: "string")
    expect(block).not_to be_valid
    expect(block.errors[:data]).to include("must be a JSON object")
  end

  it "orders blocks by position by default" do
    document = create(:document)
    # Create blocks in order to avoid position shifting issues
    block1 = create(:markdown_block, document: document, position: 1)
    block2 = create(:markdown_block, document: document, position: 2)
    block3 = create(:markdown_block, document: document, position: 3)

    expect(document.blocks.pluck(:position)).to eq([ 1, 2, 3 ])
  end

  it "auto-assigns position when nil" do
    document = create(:document)

    # First block gets position 1
    block1 = create(:markdown_block, document: document, position: nil)
    expect(block1.position).to eq(1)

    # Second block gets position 2
    block2 = create(:markdown_block, document: document, position: nil)
    expect(block2.position).to eq(2)
  end

  it "requires position to be a positive integer when provided" do
    document = create(:document)

    # Test zero position is invalid
    block = build(:markdown_block, document: document, position: 0)
    expect(block).not_to be_valid
    expect(block.errors[:position]).to include("must be greater than or equal to 1")

    # Test negative position is invalid
    block.position = -1
    expect(block).not_to be_valid
    expect(block.errors[:position]).to include("must be greater than or equal to 1")

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

  it "shifts positions when inserting at specific position" do
    document = create(:document)
    block1 = create(:markdown_block, document: document, position: 1)
    block2 = create(:markdown_block, document: document, position: 2)

    # Insert new block at position 1
    new_block = create(:markdown_block, document: document, position: 1)

    # Original blocks should be shifted
    expect(new_block.position).to eq(1)
    expect(block1.reload.position).to eq(2)
    expect(block2.reload.position).to eq(3)
  end

  it "repositions siblings when updating position" do
    document = create(:document)
    block1 = create(:markdown_block, document: document, position: 1)
    block2 = create(:markdown_block, document: document, position: 2)
    block3 = create(:markdown_block, document: document, position: 3)

    # Move block3 to position 1
    block3.update(position: 1)

    expect(block3.reload.position).to eq(1)
    expect(block1.reload.position).to eq(2)
    expect(block2.reload.position).to eq(3)
  end

  it "compacts positions after deletion" do
    document = create(:document)
    block1 = create(:markdown_block, document: document, position: 1)
    block2 = create(:markdown_block, document: document, position: 2)
    block3 = create(:markdown_block, document: document, position: 3)

    # Delete middle block
    block2.destroy

    # Positions should be compacted
    expect(block1.reload.position).to eq(1)
    expect(block3.reload.position).to eq(2)
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
