class Public::DocumentsController < Public::BaseController
  after_action :track_page_view, only: :show

  def index
    # Filter by kind if provided in defaults (for /posts route)
    kind = params[:kind] || "post"
    @documents = Document.published.where(kind: kind).order(published_at: :desc, created_at: :desc).limit(20)
  end

  def show
    @document = Document.friendly.find(params[:id])

    # Only show published documents on public site
    redirect_to public_posts_path, alert: "Document not found" unless @document.published?

    @blocks = @document.blocks.order(:position)
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
