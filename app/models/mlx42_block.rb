class Mlx42Block < Block
  has_one_attached :wasm_file
  has_one_attached :js_file
  has_one_attached :data_file
  has_one_attached :thumbnail
  has_many_attached :assets

  # Legacy support for single text field (for backward compatibility during transition)
  def text
    data.to_h["text"]
  end

  def text=(value)
    self.data = data.to_h.merge("text" => value)
  end

  # New multi-file support
  def files
    data.to_h["files"] || []
  end

  def files=(files_array)
    self.data = data.to_h.merge("files" => files_array)
  end

  # Get all .c files for compilation
  def c_files
    files.select { |f| f["filename"]&.end_with?(".c") }
  end

  # Get all .h files
  def h_files
    files.select { |f| f["filename"]&.end_with?(".h") }
  end

  # Check if using new multi-file format
  def multi_file?
    files.any?
  end

  def plain_text
    if multi_file?
      files.map { |f| "// #{f['filename']}\n#{f['content']}" }.join("\n\n")
    else
      text.to_s
    end
  end

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
