class CodeBlock < Block
  def plain_text  = data.to_h["code"].to_s
  def languages   = [ data.to_h["language"].to_s.downcase ].compact_blank
end
