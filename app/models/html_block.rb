class HtmlBlock < Block
  def plain_text
    html = data.to_h["html"].to_s
    ActionView::Base.full_sanitizer.sanitize(html).squish
  end
end
