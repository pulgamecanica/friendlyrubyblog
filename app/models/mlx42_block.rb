class Mlx42Block < Block
  has_one_attached :wasm_file
  has_one_attached :js_file
  has_one_attached :data_file
  has_one_attached :thumbnail
  has_many_attached :assets

  def text
    data.to_h["text"]
  end

  def text=(value)
    self.data = data.to_h.merge("text" => value)
  end

  def plain_text = text.to_s
  def languages = [ "c" ]

  def width
    data.to_h["width"] || 800
  end

  def height
    data.to_h["height"] || 600
  end

  def compiler_args
    data.to_h["compiler_args"] || ""
  end

  def compiled?
    wasm_file.attached? && js_file.attached?
  end

  def compilation_error
    data.to_h["compilation_error"]
  end

  def set_compilation_error(error)
    self.data = data.to_h.merge("compilation_error" => error)
  end

  def clear_compilation_error
    self.data = data.to_h.except("compilation_error")
  end
end
