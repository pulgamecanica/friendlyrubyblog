require 'rails_helper'

RSpec.describe ImageBlock, type: :model do
  it "returns plain text with caption and filenames" do
    document = create(:document)
    block = ImageBlock.create!(
      document: document,
      position: 1,
      data: { "caption" => "Beautiful sunset" }
    )

    # Attach images using Active Storage
    block.images.attach(
      io: StringIO.new("fake image 1"),
      filename: "sunset.jpg",
      content_type: "image/jpeg"
    )
    block.images.attach(
      io: StringIO.new("fake image 2"),
      filename: "beach.png",
      content_type: "image/png"
    )

    expect(block.plain_text).to include("Beautiful sunset")
    expect(block.plain_text).to include("sunset.jpg")
    expect(block.plain_text).to include("beach.png")
  end

  it "returns plain text without caption" do
    document = create(:document)
    block = ImageBlock.create!(
      document: document,
      position: 1,
      data: {}
    )

    block.images.attach(
      io: StringIO.new("fake image"),
      filename: "photo.jpg",
      content_type: "image/jpeg"
    )

    expect(block.plain_text).to eq("photo.jpg")
  end

  it "returns image count" do
    document = create(:document)
    block = ImageBlock.create!(
      document: document,
      position: 1,
      data: {}
    )

    expect(block.image_count).to eq(0)

    block.images.attach(
      io: StringIO.new("fake image"),
      filename: "photo.jpg",
      content_type: "image/jpeg"
    )

    expect(block.image_count).to eq(1)
  end

  it "identifies collection when multiple images" do
    document = create(:document)
    block = ImageBlock.create!(
      document: document,
      position: 1,
      data: {}
    )

    expect(block.is_collection?).to be false

    block.images.attach(
      io: StringIO.new("fake image 1"),
      filename: "photo1.jpg",
      content_type: "image/jpeg"
    )

    expect(block.is_collection?).to be false

    block.images.attach(
      io: StringIO.new("fake image 2"),
      filename: "photo2.jpg",
      content_type: "image/jpeg"
    )

    expect(block.is_collection?).to be true
  end
end
