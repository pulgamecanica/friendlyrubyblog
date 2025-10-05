class Public::DocumentsController < Public::BaseController
  after_action :track_page_view, only: :show

  def index
    @documents = Document.published.order(published_at: :desc).limit(20)
  end

  def show
    @document = Document.friendly.find(params[:id])
    @blocks   = @document.blocks
  end

  private

  def track_page_view
    return unless @document

    VisitorTrackingService.new(request, @document, session).track!
  rescue StandardError => e
    Rails.logger.error("Failed to track page view: #{e.message}")
    # Don't fail the request if tracking fails
  end
end
