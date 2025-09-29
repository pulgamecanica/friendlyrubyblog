module MarkdownHelper
  def text_to_markdown(text)
    str = ensure_utf8(text)

    return "" if str.empty?

    Commonmarker.to_html(
      str,
      options: { render: { unsafe: true } },
      plugins: { syntax_highlighter: { theme: "InspiredGitHub" } }
    )
  end

  def ensure_utf8(s)
    s = s.to_s

    # Empty? normalize to UTF-8 empty string
    return "".dup.force_encoding(Encoding::UTF_8) if s.empty?

    # Already UTF-8
    return s if s.encoding == Encoding::UTF_8

    # ASCII-compatible encodings (US-ASCII, ASCII-8BIT) -> clean encode to UTF-8
    if s.encoding.ascii_compatible?
      return s.encode(Encoding::UTF_8)
    end

    # Fallback for odd cases: replace invalid/undef bytes
    s.encode(Encoding::UTF_8, invalid: :replace, undef: :replace, replace: "")
  end

  def safe_html(html)
    sanitize(html.to_s,
      tags: %w[p br hr details summary a strong em code pre ul ol li h1 h2 h3 h4 h5 h6 blockquote img span div],
      attributes: %w[href stylec title rel target src alt width height class open]
    )
  end
end
