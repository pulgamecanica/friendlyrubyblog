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
