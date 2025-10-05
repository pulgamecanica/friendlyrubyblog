require "rails_helper"

RSpec.describe PublicHelper, type: :helper do
  describe "#format_date" do
    it "formats a Time/DateTime" do
      t = Time.utc(2024, 5, 7, 12, 0, 0)
      expect(helper.format_date(t)).to eq("May 7, 2024")
    end

    it "returns nil for nil" do
      expect(helper.format_date(nil)).to be_nil
    end
  end

  describe "#render_block" do
    let(:document) { create(:document) }

    context "MarkdownBlock" do
      it "renders markdown to sanitized HTML inside prose container" do
        block = Block.create!(
          document: document,
          type: "MarkdownBlock",
          position: 1,
          data: { "markdown" => "**bold** and *italic*" }
        )

        html = helper.render_block(block)

        expect(html).to include('class="prose prose-neutral max-w-none"')
        expect(html).to include("<strong>bold</strong>")
        expect(html).to include("<em>italic</em>")
        # ensure sanitization (scripts removed)
        block.update!(data: { "markdown" => '<script>alert(1)</script>' })
        html2 = helper.render_block(block)
        expect(html2).not_to include("<script>")
      end
    end

    context "CodeBlock" do
      # it "wraps code in <pre><code> with language class" do
      #   block = Block.create!(
      #     document: document,
      #     type: "CodeBlock",
      #     position: 1,
      #     data: { "language" => "ruby", "code" => "puts 'hi'" }
      #   )

      #   html = helper.render_block(block)

      #   expect(html).to include("<pre")
      #   expect(html).to include('class="rounded-lg border bg-gray-900 text-gray-100 p-4 overflow-auto"')
      #   expect(html).to include('<code class="language-ruby">')
      #   expect(html).to include("puts 'hi'")
      # end

      it "defaults language to text when missing" do
        block = Block.create!(
          document: document,
          type: "CodeBlock",
          position: 1,
          data: { "code" => "echo test" }
        )

        html = helper.render_block(block)
        expect(html).to include('<code class="language-text">')
      end
    end

    context "HtmlBlock" do
      it "renders provided HTML as-is within prose container" do
        block = Block.create!(
          document: document,
          type: "HtmlBlock",
          position: 1,
          data: { "html" => "<p>Hello <strong>world</strong></p>" }
        )

        html = helper.render_block(block)

        expect(html).to include('class="prose prose-neutral max-w-none"')
        expect(html).to include("<p>Hello <strong>world</strong></p>")
      end

      it "falls back to data['content'] when html is blank" do
        block = Block.create!(
          document: document,
          type: "HtmlBlock",
          position: 1,
          data: { "html" => "", "content" => "<em>content</em>" }
        )

        html = helper.render_block(block)
        expect(html).to include("<em>content</em>")
      end
    end

    context "ImageBlock" do
      it "renders 'No images' message when no images attached" do
        block = ImageBlock.create!(
          document: document,
          position: 1,
          data: {}
        )

        html = helper.render_block(block)

        expect(html).to include('class="text-gray-500 text-sm"')
        expect(html).to include("No images")
      end

      it "renders single image without carousel" do
        block = ImageBlock.create!(
          document: document,
          position: 1,
          data: { "caption" => "Beautiful sunset" }
        )

        block.images.attach(
          io: StringIO.new("fake image content"),
          filename: "sunset.jpg",
          content_type: "image/jpeg"
        )

        html = helper.render_block(block)

        expect(html).to include("<figure")
        expect(html).to include('class="my-6"')
        expect(html).to include('class="w-full rounded-lg shadow-lg max-h-96 object-cover mx-auto"')
        expect(html).to include("<figcaption")
        expect(html).to include("Beautiful sunset")
      end

      it "renders single image without caption" do
        block = ImageBlock.create!(
          document: document,
          position: 1,
          data: {}
        )

        block.images.attach(
          io: StringIO.new("fake image content"),
          filename: "photo.jpg",
          content_type: "image/jpeg"
        )

        html = helper.render_block(block)

        expect(html).to include("<figure")
        expect(html).not_to include("<figcaption")
      end

      it "renders multiple images with carousel" do
        block = ImageBlock.create!(
          document: document,
          position: 1,
          data: { "caption" => "Photo gallery" }
        )

        block.images.attach([
          { io: StringIO.new("image1"), filename: "img1.jpg", content_type: "image/jpeg" },
          { io: StringIO.new("image2"), filename: "img2.jpg", content_type: "image/jpeg" },
          { io: StringIO.new("image3"), filename: "img3.jpg", content_type: "image/jpeg" }
        ])

        html = helper.render_block(block)

        expect(html).to include("<figure")
        expect(html).to include('data-image-carousel-target="container"')
        expect(html).to include('class="flex transition-transform duration-300 ease-in-out"')
        expect(html).to include("<figcaption")
        expect(html).to include("Photo gallery")
      end

      it "renders multiple images without caption" do
        block = ImageBlock.create!(
          document: document,
          position: 1,
          data: {}
        )

        block.images.attach([
          { io: StringIO.new("image1"), filename: "img1.jpg", content_type: "image/jpeg" },
          { io: StringIO.new("image2"), filename: "img2.jpg", content_type: "image/jpeg" }
        ])

        html = helper.render_block(block)

        expect(html).to include('data-image-carousel-target="container"')
        expect(html).not_to include("<figcaption")
      end
    end

    context "Mlx42Block" do
      it "renders 'not compiled yet' message when not compiled" do
        block = Mlx42Block.create!(
          document: document,
          position: 1,
          data: { "text" => "#include <MLX42/MLX42.h>\nvoid user_main() {}" }
        )

        html = helper.render_block(block)

        expect(html).to include('class="text-gray-500 text-sm p-4 bg-gray-50 rounded"')
        expect(html).to include("MLX42 block not compiled yet")
      end

      it "renders MLX42 runner when compiled" do
        block = Mlx42Block.create!(
          document: document,
          position: 1,
          data: { "text" => "#include <MLX42/MLX42.h>\nvoid user_main() {}" }
        )

        # Attach compiled files
        block.wasm_file.attach(
          io: StringIO.new("fake wasm"),
          filename: "mlx42_output.wasm",
          content_type: "application/wasm"
        )
        block.js_file.attach(
          io: StringIO.new("fake js"),
          filename: "mlx42_output.js",
          content_type: "application/javascript"
        )

        html = helper.render_block(block)

        expect(html).to include('data-controller="mlx42-runner"')
        expect(html).to include("mlx42-runner-block-id-value=\"#{block.id}\"")
        expect(html).to include('data-mlx42-runner-target="canvas"')
        expect(html).to include("mlx42_canvas_#{block.id}")
        expect(html).to include('data-mlx42-runner-target="console"')
        expect(html).to include("mlx42_console_#{block.id}")
        expect(html).to include('data-mlx42-runner-target="loader"')
        expect(html).to include("Loading WebAssembly...")
        expect(html).to include("Console Output")
        expect(html).to include("🖱️ Mouse Captured")
      end

      it "renders MLX42 runner with data file when attached" do
        block = Mlx42Block.create!(
          document: document,
          position: 1,
          data: { "text" => "#include <MLX42/MLX42.h>\nvoid user_main() {}" }
        )

        block.wasm_file.attach(
          io: StringIO.new("fake wasm"),
          filename: "mlx42_output.wasm",
          content_type: "application/wasm"
        )
        block.js_file.attach(
          io: StringIO.new("fake js"),
          filename: "mlx42_output.js",
          content_type: "application/javascript"
        )
        block.data_file.attach(
          io: StringIO.new("fake data"),
          filename: "mlx42_output.data",
          content_type: "application/octet-stream"
        )

        html = helper.render_block(block)

        expect(html).to include('data-controller="mlx42-runner"')
        # Data URL should be present (not empty)
        expect(html).to match(/mlx42-runner-data-url-value="[^"]+"/)
      end

      it "renders MLX42 runner without data file when not attached" do
        block = Mlx42Block.create!(
          document: document,
          position: 1,
          data: { "text" => "#include <MLX42/MLX42.h>\nvoid user_main() {}" }
        )

        block.wasm_file.attach(
          io: StringIO.new("fake wasm"),
          filename: "mlx42_output.wasm",
          content_type: "application/wasm"
        )
        block.js_file.attach(
          io: StringIO.new("fake js"),
          filename: "mlx42_output.js",
          content_type: "application/javascript"
        )

        html = helper.render_block(block)

        expect(html).to include('data-controller="mlx42-runner"')
        # Data URL should be empty string
        expect(html).to include('mlx42-runner-data-url-value=""')
      end
    end

    # context "unknown block type" do
    #   it "renders a fallback inspector" do
    #     block = Block.create!(
    #       document: document,
    #       type: "UnknownBlock",
    #       position: 1,
    #       data: { "foo" => "bar" }
    #     )

    #     html = helper.render_block(block)
    #     expect(html).to include('class="text-xs text-gray-500"')
    #     expect(html).to include("foo")
    #     expect(html).to include("bar")
    #   end
    # end
  end

  describe "#safe_html" do
    it "keeps allowed tags and attributes" do
      html = '<p class="x">Hello <a href="https://ex.com" title="t" target="_blank" rel="noreferrer">link</a></p>'
      result = helper.safe_html(html)
      expect(result).to include('<p class="x">Hello ')
      expect(result).to include('href="https://ex.com"')
      expect(result).to include('title="t"')
      expect(result).to include('target="_blank"')
      expect(result).to include('rel="noreferrer"')
    end

    it "removes disallowed tags/attributes" do
      html = '<p onclick="evil()">X</p><script>alert(1)</script>'
      result = helper.safe_html(html)
      expect(result).to include("<p>X</p>")
      expect(result).not_to include("onclick=")
      expect(result).not_to include("<script>")
    end

    it "allows images with safe attributes" do
      html = '<img src="/img.png" alt="a" width="10" height="20" class="pic">'
      result = helper.safe_html(html)
      expect(result).to include('src="/img.png"')
      expect(result).to include('alt="a"')
      expect(result).to include('width="10"')
      expect(result).to include('height="20"')
      expect(result).to include('class="pic"')
    end

    it "handles non-string and nil" do
      expect(helper.safe_html(123)).to eq("123")
      expect(helper.safe_html(nil)).to eq("")
    end
  end
end
