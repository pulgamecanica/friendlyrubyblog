class Public::TagsController < Public::BaseController
  def show
    @tag       = Tag.friendly.find(params[:id])
    @documents = @tag.documents.published.order(published_at: :desc)
  end
end
