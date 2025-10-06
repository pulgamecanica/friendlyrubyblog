class Public::TagsController < Public::BaseController
  def show
    @tag       = Tag.friendly.find(params[:id])
    @documents = @tag.documents.published.order(published_at: :desc)
    @all_tags  = Tag.joins(:documents).where(documents: { published: true }).distinct.order(:title)
  end
end
