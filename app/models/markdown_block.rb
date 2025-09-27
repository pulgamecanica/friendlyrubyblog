class MarkdownBlock < Block
  def plain_text
    md = data.to_h["markdown"].to_s
    md.gsub(/```.*?```/m, " ").gsub(/`[^`]+`/, " ").gsub(/[>#*_~`]/, " ").squish
  end
  def languages
    data.to_h["markdown"].to_s.scan(/```(\w+)/).flatten.map(&:downcase).uniq
  end
end
