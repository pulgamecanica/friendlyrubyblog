class ImageBlock < Block
  has_many_attached :images

  def plain_text
    images_text = images.map { |img| img.blob.filename.to_s }.join(" ")
    [data.to_h["caption"], images_text].compact_blank.join(" ")
  end

  def image_count
    images.count
  end

  def is_collection?
    image_count > 1
  end
end