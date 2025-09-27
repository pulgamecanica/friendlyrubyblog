class Public::SeriesController < Public::BaseController
  def index
    @series = Series.order(:title)
  end

  def show
    @series    = Series.friendly.find(params[:id])
    @documents = @series.documents.published
  end
end
