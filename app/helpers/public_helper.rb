module PublicHelper
  def format_date(dt)
    dt&.strftime("%b %-d, %Y")
  end

  # Minimal block renderer; will expand later
  def render_block(block)
    case block
    when MarkdownBlock
      html = Commonmarker.to_html(block.data["markdown"].to_s)
      html = safe_html(html)
      sanitized = Sanitize.fragment(html, Sanitize::Config::RELAXED)
      content_tag(:div, sanitized.html_safe, class: "prose prose-neutral max-w-none")
    when CodeBlock
      lang = block.data["language"].presence || "text"
      code = block.data["code"].to_s
      content_tag(:pre, class: "rounded-lg border bg-gray-900 text-gray-100 p-4 overflow-auto") do
        content_tag(:code, code, class: "language-#{lang}")
      end
    when RichTextBlock
      html = block.data["html"].to_s.presence || block.data["content"].to_s
      content_tag(:div, html.html_safe, class: "prose prose-neutral max-w-none")
    else
      # fallback
      content_tag(:div, block.data.inspect, class: "text-xs text-gray-500")
    end
  end

  def safe_html(html)
    sanitize(html.to_s,
      tags: %w[p br a strong em code pre ul ol li h1 h2 h3 h4 h5 h6 blockquote img span div],
      attributes: %w[href title rel target src alt width height class]
    )
  end
end
