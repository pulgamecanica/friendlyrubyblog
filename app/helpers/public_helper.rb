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
    when Mlx42Block
      render_mlx42_block(block)
    else
      # fallback
      content_tag(:div, block.data.inspect, class: "text-xs text-gray-500")
    end
  end

  private

  def render_mlx42_block(block)
    return content_tag(:div, "MLX42 block not compiled yet", class: "text-gray-500 text-sm p-4 bg-gray-50 rounded") unless block.compiled?

    content_tag(:div, class: "my-6", data: { controller: "mlx42-runner", mlx42_runner_js_url_value: rails_blob_url(block.js_file), mlx42_runner_wasm_url_value: rails_blob_url(block.wasm_file), mlx42_runner_data_url_value: (block.data_file.attached? ? rails_blob_url(block.data_file) : ""), mlx42_runner_block_id_value: block.id }) do
      canvas_container = content_tag(:div, class: "border-2 border-purple-300 rounded-lg overflow-hidden bg-black relative") do
        canvas = content_tag(:canvas, "", id: "mlx42_canvas_#{block.id}", data: { mlx42_runner_target: "canvas" }, tabindex: "-1", class: "w-full")
        indicator = content_tag(:div, "🖱️ Mouse Captured (ESC to release)", data: { mlx42_runner_target: "captureIndicator" }, style: "display: none;", class: "absolute top-2 right-2 bg-red-600 text-white text-xs px-2 py-1 rounded shadow-lg")
        canvas + indicator
      end

      console_section = content_tag(:div, class: "mt-4") do
        header = content_tag(:div, class: "flex items-center justify-between mb-2") do
          title = content_tag(:div, "Console Output", class: "text-sm font-medium text-gray-700")
          clear_btn = content_tag(:button, "Clear", type: "button", onclick: "document.getElementById('mlx42_console_#{block.id}').value = ''", class: "text-xs text-gray-500 hover:text-gray-700")
          title + clear_btn
        end
        console_output = content_tag(:textarea, "", id: "mlx42_console_#{block.id}", data: { mlx42_runner_target: "console" }, rows: 8, readonly: true, class: "w-full font-mono text-xs bg-gray-900 text-green-400 p-4 rounded border border-gray-700 focus:outline-none")
        header + console_output
      end

      loader = content_tag(:div, data: { mlx42_runner_target: "loader" }, class: "absolute inset-0 bg-white bg-opacity-95 flex items-center justify-center rounded-lg") do
        content_tag(:div, class: "text-center") do
          spinner = content_tag(:div, "", class: "inline-block animate-spin rounded-full h-8 w-8 border-4 border-purple-500 border-t-transparent")
          text = content_tag(:p, "Loading WebAssembly...", class: "mt-2 text-gray-600 text-sm font-medium")
          spinner + text
        end
      end

      canvas_container + console_section + loader
    end
  end

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
