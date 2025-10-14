module MarkdownHelper
  def text_to_markdown(text)
    str = ensure_utf8(text)

    return "" if str.empty?

    Commonmarker.to_html(
      str,
      options: { render: { unsafe: true } },
      plugins: { syntax_highlighter: { theme: "base16-ocean.light" } }
    )
  end

  def ensure_utf8(s)
    s = s.to_s

    # Empty? normalize to UTF-8 empty string
    return "".dup.force_encoding(Encoding::UTF_8) if s.empty?

    # Already UTF-8
    return s if s.encoding == Encoding::UTF_8

    s.encode(Encoding::UTF_8)
  end


  def safe_html(html)
    sanitize(html.to_s,
      tags: %w[p br hr a strong em code pre ul ol li h1 h2 h3 h4 h5 h6 blockquote img span div],
      attributes: %w[href style title rel target src alt width height class]
    )
  end
end
