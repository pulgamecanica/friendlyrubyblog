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
    when HtmlBlock
      html = block.data["html"].to_s.presence || block.data["content"].to_s
      content_tag(:div, html.html_safe, class: "prose prose-neutral max-w-none")
    when ImageBlock
      render_image_block(block)
    else
      # fallback
      content_tag(:div, block.data.inspect, class: "text-xs text-gray-500")
    end
  end

  private

  def render_image_block(block)
    return content_tag(:div, "No images", class: "text-gray-500 text-sm") if block.images.blank?

    caption = block.data["caption"].presence
    images = block.images

    if images.count == 1
      # Single image - no carousel
      content_tag(:figure, class: "my-6") do
        img_tag = image_tag(images.first,
                           class: "w-full rounded-lg shadow-lg max-h-96 object-cover mx-auto",
                           alt: caption || "Image")
        if caption
          img_tag + content_tag(:figcaption, caption, class: "text-center text-sm text-gray-600 mt-2")
        else
          img_tag
        end
      end
    else
      # Multiple images - carousel/grid
      content_tag(:figure, class: "my-6") do
        carousel_content = content_tag(:div, class: "relative") do
          # Images container only (no navigation buttons)
          content_tag(:div, class: "overflow-hidden rounded-lg") do
            content_tag(:div,
                       class: "flex transition-transform duration-300 ease-in-out",
                       data: { "image-carousel-target": "container" }) do
              images.map.with_index do |image, index|
                content_tag(:div, class: "w-full flex-shrink-0") do
                  image_tag(image,
                           class: "w-full h-96 object-cover",
                           alt: "Image #{index + 1}")
                end
              end.join.html_safe
            end
          end
        end

        if caption
          carousel_content + content_tag(:figcaption, caption, class: "text-center text-sm text-gray-600 mt-2")
        else
          carousel_content
        end
      end
    end
  end
end
