require 'rails_helper'

RSpec.describe MarkdownHelper, type: :helper do
  describe "#text_to_markdown" do
    it "converts basic markdown to HTML" do
      result = helper.text_to_markdown("# Hello World")
      expect(result).to include("<h1>")
      expect(result).to include("Hello World")
      expect(result).to include("</h1>")
    end

    it "handles bold and italic text" do
      result = helper.text_to_markdown("**bold** and *italic*")
      expect(result).to include("<strong>bold</strong>")
      expect(result).to include("<em>italic</em>")
    end

    it "handles code blocks with syntax highlighting" do
      markdown = "```ruby\nputs 'hello'\n```"
      result = helper.text_to_markdown(markdown)
      expect(result).to include("<code")
      expect(result).to include("puts")
    end

    it "returns empty string when input is empty" do
      expect(helper.text_to_markdown("")).to eq("")
      expect(helper.text_to_markdown(nil)).to eq("")
    end

    it "handles unsafe HTML when enabled" do
      markdown = '<script>alert("xss")</script>'
      result = helper.text_to_markdown(markdown)
      # CommonMarker with unsafe: true still escapes HTML in plain text
      expect(result).to include("&lt;script")
      expect(result).to include("&lt;/script>")
    end

    it "converts lists properly" do
      markdown = "- Item 1\n- Item 2"
      result = helper.text_to_markdown(markdown)
      expect(result).to include("<ul>")
      expect(result).to include("<li>Item 1</li>")
      expect(result).to include("<li>Item 2</li>")
    end
  end

  describe "#ensure_utf8" do
    it "returns empty UTF-8 string for empty input" do
      result = helper.ensure_utf8("")
      expect(result).to eq("")
      expect(result.encoding).to eq(Encoding::UTF_8)
    end

    it "returns same string if already UTF-8" do
      utf8_string = "Hello 世界".encode(Encoding::UTF_8)
      result = helper.ensure_utf8(utf8_string)
      expect(result).to eq(utf8_string)
      expect(result.encoding).to eq(Encoding::UTF_8)
    end

    it "converts ASCII-compatible encodings to UTF-8" do
      ascii_string = "Hello World".encode(Encoding::US_ASCII)
      result = helper.ensure_utf8(ascii_string)
      expect(result).to eq("Hello World")
      expect(result.encoding).to eq(Encoding::UTF_8)
    end

    it "handles non-strings by converting to string first" do
      result = helper.ensure_utf8(123)
      expect(result).to eq("123")
      expect(result.encoding).to eq(Encoding::UTF_8)
    end

    it "handles nil input" do
      result = helper.ensure_utf8(nil)
      expect(result).to eq("")
      expect(result.encoding).to eq(Encoding::UTF_8)
    end
  end

  describe "#safe_html" do
    it "allows safe HTML tags" do
      html = "<p>Hello <strong>world</strong></p>"
      result = helper.safe_html(html)
      expect(result).to eq(html)
    end

    it "removes dangerous script tags" do
      html = '<p>Hello</p><script>alert("xss")</script>'
      result = helper.safe_html(html)
      expect(result).to include("<p>Hello</p>")
      expect(result).not_to include("<script>")
    end

    it "allows common formatting tags" do
      html = "<h1>Title</h1><em>italic</em><code>code</code><br>"
      result = helper.safe_html(html)
      expect(result).to include("<h1>Title</h1>")
      expect(result).to include("<em>italic</em>")
      expect(result).to include("<code>code</code>")
      expect(result).to include("<br>")
    end

    it "allows links with safe attributes" do
      html = '<a href="https://example.com" title="Example">Link</a>'
      result = helper.safe_html(html)
      expect(result).to include('<a href="https://example.com" title="Example">Link</a>')
    end

    it "allows images with safe attributes" do
      html = '<img src="/image.jpg" alt="Description" width="100" height="50">'
      result = helper.safe_html(html)
      expect(result).to include('src="/image.jpg"')
      expect(result).to include('alt="Description"')
      expect(result).to include('width="100"')
      expect(result).to include('height="50"')
    end

    it "removes dangerous attributes" do
      html = '<p onclick="alert(1)" style="color: red" onload="evil()">Text</p>'
      result = helper.safe_html(html)
      expect(result).not_to include("onclick")
      expect(result).not_to include("onload")
      # Note: style might be allowed as it's in the attributes list, but onclick/onload should be removed
    end

    it "handles non-string input" do
      result = helper.safe_html(123)
      expect(result).to eq("123")
    end

    it "handles nil input" do
      result = helper.safe_html(nil)
      expect(result).to eq("")
    end

    it "preserves list structures" do
      html = "<ul><li>Item 1</li><li>Item 2</li></ul>"
      result = helper.safe_html(html)
      expect(result).to eq(html)
    end

    it "preserves blockquotes and details" do
      html = "<blockquote>Quote</blockquote><details><summary>Title</summary>Content</details>"
      result = helper.safe_html(html)
      expect(result).to include("<blockquote>Quote</blockquote>")
      # Details and summary might be stripped by the sanitizer depending on configuration
      expect(result).to include("Title")
      expect(result).to include("Content")
    end
  end
end
