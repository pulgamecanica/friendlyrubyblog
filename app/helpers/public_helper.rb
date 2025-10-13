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

      # Wrap code blocks with copy button
      enhanced_html = sanitized.gsub(/<pre><code>(.*?)<\/code><\/pre>/m) do |match|
        code_content = $1
        %{
          <div class="not-prose relative my-4 group">
            <button type="button" onclick="navigator.clipboard.writeText(this.nextElementSibling.querySelector('code').textContent); this.textContent = 'Copied!'; setTimeout(() => this.textContent = 'Copy', 2000)" class="absolute right-2 top-2 z-10 px-2 py-1 text-xs font-medium text-gray-600 hover:text-gray-900 bg-gray-200 hover:bg-gray-300 rounded transition-colors opacity-0 group-hover:opacity-100">Copy</button>
            <pre class="!bg-white !text-gray-900 !p-4 !rounded-lg !my-0 !border !border-gray-200"><code>#{code_content}</code></pre>
          </div>
        }
      end

      content_tag(:div, enhanced_html.html_safe, class: "prose prose-neutral max-w-none prose-p:my-0 prose-p:mb-2 prose-headings:my-0 prose-headings:mb-1 prose-ul:my-0 prose-ul:mb-2 prose-ol:my-0 prose-ol:mb-2 prose-li:my-0 prose-code:bg-gray-100 prose-code:text-gray-800 prose-code:px-1.5 prose-code:py-0.5 prose-code:rounded prose-code:text-sm prose-pre:!bg-white prose-code:!bg-transparent")
    when CodeBlock
      render_code_block(block)
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

  def render_code_block(block)
    lang = block.data["language"].presence || "text"
    code = block.data["code"].to_s
    is_interactive = block.interactive
    execution_result = block.execution_result

    # Extract output from execution result hash
    output = if execution_result.is_a?(Hash)
      execution_result["output"] || execution_result["error"] || execution_result.to_s
    else
      execution_result
    end

    content_tag(:div, class: "not-prose relative my-6 group") do
      # Header with language badge, interactive badge, and copy button
      header = content_tag(:div, class: "flex items-center justify-between px-4 py-2 bg-gray-100 rounded-t-lg border-b border-gray-300") do
        left_side = content_tag(:div, class: "flex items-center gap-2") do
          lang_badge = content_tag(:span, lang.upcase, class: "text-xs font-semibold text-gray-600")
          interactive_badge = is_interactive ? content_tag(:span, "INTERACTIVE", class: "text-xs font-semibold text-green-600 bg-green-100 px-2 py-0.5 rounded") : "".html_safe
          lang_badge + interactive_badge
        end

        copy_btn = content_tag(:button,
          type: "button",
          onclick: "navigator.clipboard.writeText(this.closest('.group').querySelector('code').textContent); this.textContent = 'Copied!'; setTimeout(() => this.textContent = 'Copy', 2000)",
          class: "flex items-center gap-1.5 px-3 py-1 text-xs font-medium text-gray-600 hover:text-gray-900 hover:bg-gray-200 rounded transition-colors") do
          svg = %(<svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z"/></svg>).html_safe
          svg + content_tag(:span, "Copy")
        end
        left_side + copy_btn
      end

      # Code block with syntax highlighting
      code_wrapper = content_tag(:div,
        data: { controller: "syntax-highlighter", syntax_highlighter_language_value: lang },
        class: "#{is_interactive && output ? 'overflow-hidden' : 'rounded-b-lg overflow-hidden'} [&_pre]:!bg-white [&_code]:!bg-transparent",
        style: "background-color: white !important;") do
        content_tag(:pre, class: "m-0 rounded-none p-4 overflow-x-auto max-h-96 !bg-white !text-gray-900", style: "background-color: white !important; color: #1f2937 !important;") do
          content_tag(:code, code, class: "language-#{lang} !bg-transparent", style: "background-color: transparent !important; color: inherit !important;", data: { syntax_highlighter_target: "code" })
        end
      end

      # Console output (only for interactive blocks with execution results)
      console_section = if is_interactive && output.present?
        content_tag(:div, class: "border-t border-gray-300 bg-gray-100 p-4 rounded-b-lg") do
          header_console = content_tag(:div, class: "flex items-center gap-2 mb-2") do
            svg = %(<svg class="h-4 w-4 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 9l3 3-3 3m5 0h3M5 20h14a2 2 0 002-2V6a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/></svg>).html_safe
            svg + content_tag(:span, "Console Output", class: "text-sm font-medium text-gray-600")
          end
          console_output = content_tag(:pre, class: "p-3 rounded font-mono text-sm overflow-x-auto max-h-48", style: "background-color: white !important; color: #16a34a; margin: 0;") do
            content_tag(:code, output)
          end
          header_console + console_output
        end
      else
        "".html_safe
      end

      header + code_wrapper + console_section
    end
  end

  def render_mlx42_block(block)
    return content_tag(:div, "MLX42 program not compiled yet", class: "text-gray-500 text-sm p-4 bg-gray-50 rounded") unless block.compiled?

    modal_id = "mlx42-modal-#{block.id}"

    content_tag(:div, class: "my-6 not-prose", data: { controller: "mlx42-public", mlx42_public_js_url_value: rails_blob_url(block.js_file), mlx42_public_wasm_url_value: rails_blob_url(block.wasm_file), mlx42_public_data_url_value: (block.data_file.attached? ? rails_blob_url(block.data_file) : ""), mlx42_public_block_id_value: block.id }) do
      # Header with controls
      header = content_tag(:div, class: "flex items-center justify-between px-4 py-2 bg-purple-100 rounded-t-lg border-b border-purple-200") do
        left_side = content_tag(:div, class: "flex items-center gap-2") do
          content_tag(:span, "MLX42 PROGRAM", class: "text-xs font-semibold text-purple-700") +
          content_tag(:span, "INTERACTIVE", class: "text-xs font-semibold text-green-600 bg-green-100 px-2 py-0.5 rounded")
        end

        right_side = content_tag(:div, class: "flex items-center gap-2") do
          # Toggle Code View
          toggle_code = content_tag(:button, type: "button", data: { action: "mlx42-public#toggleCode" }, class: "text-xs px-2 py-1 bg-purple-200 hover:bg-purple-300 text-purple-700 rounded transition-colors", title: "Show/Hide Code") do
            %(<svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 20l4-16m4 4l4 4-4 4M6 16l-4-4 4-4"/></svg>).html_safe
          end

          # Toggle Console
          toggle_console = content_tag(:button, type: "button", data: { action: "mlx42-public#toggleConsole" }, class: "text-xs px-2 py-1 bg-purple-200 hover:bg-purple-300 text-purple-700 rounded transition-colors", title: "Toggle Console") do
            %(<svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 9l3 3-3 3m5 0h3M5 20h14a2 2 0 002-2V6a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/></svg>).html_safe
          end

          # Toggle Controls
          toggle_controls = content_tag(:button, type: "button", data: { action: "mlx42-public#toggleControls", mlx42_public_target: "controlsButton" }, class: "text-xs px-2 py-1 bg-purple-200 hover:bg-purple-300 text-purple-700 rounded transition-colors", title: "Toggle Controls") do
            %(<svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"/></svg>).html_safe
          end

          # Fullscreen button
          fullscreen_btn = content_tag(:button, type: "button", data: { action: "mlx42-public#openFullscreen" }, class: "text-xs px-2 py-1 bg-purple-200 hover:bg-purple-300 text-purple-700 rounded transition-colors", title: "Fullscreen") do
            %(<svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 8V4m0 0h4M4 4l5 5m11-1V4m0 0h-4m4 0l-5 5M4 16v4m0 0h4m-4 0l5-5m11 5l-5-5m5 5v-4m0 4h-4"/></svg>).html_safe
          end

          toggle_code + toggle_console + toggle_controls + fullscreen_btn
        end

        left_side + right_side
      end

      # Canvas container
      canvas_container = content_tag(:div, class: "relative bg-black rounded-b-lg", data: { mlx42_public_target: "canvasContainer" }) do
        canvas = content_tag(:canvas, "", data: { mlx42_public_target: "canvas" }, class: "w-full h-[500px]") +

        # Control indicator
        content_tag(:div, data: { mlx42_public_target: "controlsIndicator" }, class: "absolute top-2 left-2 bg-green-600 text-white text-xs px-3 py-1.5 rounded-lg shadow-lg hidden") do
          %(<div class="flex items-center gap-2"><svg class="h-4 w-4 animate-pulse" fill="currentColor" viewBox="0 0 24 24"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg><span>Controls Active (Click to release)</span></div>).html_safe
        end +

        # Loader
        content_tag(:div, data: { mlx42_public_target: "loader" }, class: "absolute inset-0 bg-black bg-opacity-90 flex items-center justify-center") do
          content_tag(:div, class: "text-center") do
            spinner = content_tag(:div, "", class: "inline-block animate-spin rounded-full h-12 w-12 border-4 border-purple-500 border-t-transparent")
            text = content_tag(:p, "Loading MLX42 Program...", class: "mt-4 text-white text-sm font-medium")
            spinner + text
          end
        end
      end

      # Code section (collapsible)
      code_section = content_tag(:div, data: { mlx42_public_target: "codeSection" }, class: "border-t border-purple-200 bg-white p-4 hidden rounded-b-lg") do
        header_code = content_tag(:div, class: "flex items-center justify-between mb-2") do
          title = content_tag(:div, class: "flex items-center gap-2 text-sm font-medium text-gray-700") do
            %(<svg class="h-4 w-4 text-purple-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 20l4-16m4 4l4 4-4 4M6 16l-4-4 4-4"/></svg><span>Source Code</span>).html_safe
          end
          lang_badge = content_tag(:span, "C", class: "text-xs font-semibold text-gray-500 bg-gray-100 px-2 py-0.5 rounded")
          title + lang_badge
        end
        code_content = content_tag(:pre, class: "bg-white text-gray-900 p-4 rounded border border-gray-200 overflow-x-auto max-h-96 text-sm") do
          content_tag(:code, block.text || "// No source code available", class: "language-c")
        end
        header_code + code_content
      end

      # Console (collapsible)
      console_section = content_tag(:div, data: { mlx42_public_target: "consoleSection" }, class: "border-t border-purple-200 bg-gray-50 p-4 hidden rounded-b-lg") do
        header_console = content_tag(:div, class: "flex items-center justify-between mb-2") do
          title = content_tag(:div, class: "flex items-center gap-2 text-sm font-medium text-gray-700") do
            %(<svg class="h-4 w-4 text-purple-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 9l3 3-3 3m5 0h3M5 20h14a2 2 0 002-2V6a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/></svg><span>Console Output</span>).html_safe
          end
          clear_btn = content_tag(:button, "Clear", type: "button", data: { action: "mlx42-public#clearConsole" }, class: "text-xs text-gray-500 hover:text-gray-700 font-medium")
          title + clear_btn
        end
        console_output = content_tag(:textarea, "", data: { mlx42_public_target: "console" }, rows: 8, readonly: true, class: "w-full font-mono text-xs bg-gray-900 text-green-400 p-3 rounded border border-gray-700 focus:outline-none")
        header_console + console_output
      end

      # Fullscreen modal
      modal = render partial: "public/mlx42/modal", locals: { modal_id: modal_id, block_id: block.id }

      header + canvas_container + code_section + console_section + modal.html_safe
    end
  end

  def render_image_block(block, clickable: true)
    return content_tag(:div, "No images", class: "text-gray-500 text-sm") unless block.images.attached?

    caption = block.data["caption"].presence
    images = block.images.to_a
    modal_id = "image-modal-#{block.id}"

    content_tag(:figure, class: "my-6") do
      images_html = if images.count == 1
        # Single image - clickable to open modal (only if clickable is true)
        if clickable
          content_tag(:button,
                     type: "button",
                     onclick: "document.getElementById('#{modal_id}').showModal()",
                     class: "block w-full group cursor-pointer") do
            content_tag(:div, class: "relative rounded-xl overflow-hidden shadow-lg h-96 flex items-center justify-center bg-gray-100") do
              image_tag(images.first,
                       class: "max-w-full max-h-full object-contain transition-transform group-hover:scale-105",
                       alt: caption || "Image") +
              content_tag(:div, class: "absolute inset-0 bg-black/0 group-hover:bg-black/10 transition-colors flex items-center justify-center") do
                content_tag(:svg, class: "h-12 w-12 text-white opacity-0 group-hover:opacity-100 transition-opacity", fill: "none", stroke: "currentColor", viewBox: "0 0 24 24") do
                  %(<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0zM10 7v6m3-3H7"></path>).html_safe
                end
              end
            end
          end
        else
          # Non-clickable single image
          content_tag(:div, class: "rounded-xl overflow-hidden shadow-lg h-96 flex items-center justify-center bg-gray-100") do
            image_tag(images.first,
                     class: "max-w-full max-h-full object-contain",
                     alt: caption || "Image")
          end
        end
      else
        # Multiple images - carousel
        # NOTE: In author view, carousel controller is on the article element
        # In public view, we need it here since there's no article wrapper
        carousel_attrs = clickable ? { controller: "image-carousel", image_carousel_count_value: images.count } : {}
        content_tag(:div,
                   class: "relative",
                   data: carousel_attrs) do
          # Images container
          images_container = content_tag(:div, class: "overflow-hidden rounded-xl shadow-lg h-96 bg-gray-100") do
            content_tag(:div,
                       class: "flex transition-transform duration-300 ease-in-out h-full",
                       data: { image_carousel_target: "container" }) do
              images.map.with_index do |image, index|
                if clickable
                  content_tag(:button,
                             type: "button",
                             onclick: "const modal = document.getElementById('#{modal_id}'); modal.dataset.startIndex = #{index}; modal.showModal();",
                             class: "w-full flex-shrink-0 cursor-pointer h-full flex items-center justify-center") do
                    image_tag(image,
                             class: "max-w-full max-h-full object-contain hover:opacity-95 transition-opacity",
                             alt: "Image #{index + 1}")
                  end
                else
                  content_tag(:div, class: "w-full flex-shrink-0 h-full flex items-center justify-center") do
                    image_tag(image,
                             class: "max-w-full max-h-full object-contain",
                             alt: "Image #{index + 1}")
                  end
                end
              end.join.html_safe
            end
          end

          # Previous button
          prev_btn = content_tag(:button,
                                type: "button",
                                data: { action: "image-carousel#previous" },
                                class: "absolute left-2 top-1/2 -translate-y-1/2 bg-black/50 hover:bg-black/70 text-white p-2 rounded-full transition-colors z-10") do
            %(<svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/></svg>).html_safe
          end

          # Next button
          next_btn = content_tag(:button,
                                type: "button",
                                data: { action: "image-carousel#next" },
                                class: "absolute right-2 top-1/2 -translate-y-1/2 bg-black/50 hover:bg-black/70 text-white p-2 rounded-full transition-colors z-10") do
            %(<svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/></svg>).html_safe
          end

          # Indicators (only in public view, toolbar has them in author view)
          indicators = if clickable
            content_tag(:div, class: "absolute bottom-4 left-1/2 -translate-x-1/2 flex gap-2 z-10") do
              images.map.with_index do |_, index|
                content_tag(:button,
                           "",
                           type: "button",
                           data: { action: "image-carousel#goTo", index: index, image_carousel_target: "indicator" },
                           class: "h-2 w-2 rounded-full bg-gray-300 transition-colors")
              end.join.html_safe
            end
          else
            "".html_safe
          end

          images_container + prev_btn + next_btn + indicators
        end
      end

      caption_html = caption ? content_tag(:figcaption, caption, class: "text-center text-sm text-gray-600 mt-3") : "".html_safe

      # Render modal (only if clickable is true)
      modal_html = if clickable
        render partial: "public/images/modal", locals: {
          modal_id: modal_id,
          images: images,
          caption: caption,
          current_index: 0
        }
      else
        "".html_safe
      end

      images_html + caption_html + modal_html
    end
  end
end
