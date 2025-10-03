class CodeBlock < Block
  belongs_to :language, optional: true

  validate :interactive_requires_supported_language
  before_save :auto_disable_interactive_for_unsupported_language

  def plain_text  = data.to_h["code"].to_s
  def languages   = language ? [language.extension] : [ data.to_h["language"].to_s.downcase ].compact_blank

  def language_name
    language&.name || data.to_h["language"].to_s
  end

  def filename
    data.to_h["filename"].to_s
  end

  def filename=(name)
    self.data = data.to_h.merge("filename" => name)
  end

  def can_be_interactive?
    language&.interactive?
  end

  def supports_execution?
    interactive? && language&.supports_execution?
  end

  def execution_result
    return nil unless supports_execution?
    data.to_h["execution_result"]
  end

  def set_execution_result(result)
    self.data = data.to_h.merge("execution_result" => result)
  end

  # Handle language assignment from string (for backward compatibility)
  def language_name=(name)
    return if name.blank?

    self.language = Language.find_or_create_by_name(name)
    # Also update the data hash for backward compatibility
    self.data = data.to_h.merge("language" => name)
  end

  private

  def interactive_requires_supported_language
    return unless interactive?
    return if language&.interactive?

    errors.add(:interactive, "cannot be enabled for languages that don't support interactivity")
  end

  def auto_disable_interactive_for_unsupported_language
    if interactive? && language && !language.interactive?
      self.interactive = false
    end
  end
end
