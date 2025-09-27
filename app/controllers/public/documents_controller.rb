class Public::DocumentsController < Public::BaseController
  def index
    @documents = Document.published.order(published_at: :desc).limit(20)
  end

  def show
    @document = Document.friendly.find(params[:id])
    @blocks   = @document.blocks
  end
end
