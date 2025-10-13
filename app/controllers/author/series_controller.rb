class Author::SeriesController < Author::BaseController
  before_action :set_series, only: %i[edit update destroy remove_portrait]

  def index
    @series = Series.order(updated_at: :desc)
  end

  def new
    @series = Series.new
  end

  def create
    @series = Series.new(series_params)
    if @series.save
      redirect_to edit_author_series_path(@series), notice: "Series created"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @series.update(series_params)
      redirect_to author_series_index_path, notice: "Series updated"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @series.destroy
    redirect_to author_series_index_path, notice: "Series deleted"
  end

  def remove_portrait
    @series.portrait.purge
    redirect_to edit_author_series_path(@series), notice: "Portrait removed"
  end

  private

  def set_series = @series = Series.friendly.find(params[:id])
  def series_params = params.require(:series).permit(:title, :slug, :portrait, :description)
end
