module Public
  class PagesController < BaseController
    def index
      @documents = Document.published.pages.order(series_position: :asc, created_at: :desc)
    end

    def show
      @document = Document.friendly.find(params[:id])

      # Only show published pages
      unless @document.published? && @document.kind == "page"
        redirect_to public_pages_path, alert: "Page not found"
        return
      end

      @blocks = @document.blocks.order(:position)
    end
  end
end
