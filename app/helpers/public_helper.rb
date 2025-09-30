module PublicHelper
  def format_date(dt)
    dt&.strftime("%b %-d, %Y")
  end

  # Minimal block renderer; will expand later
  def render_block(block)
    case block
    when MarkdownBlock
      html = text_to_markdown(block.data["markdown"].to_s)
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
end
