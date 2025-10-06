module Public
  class NotesController < BaseController
    before_action :authenticate_author!

    def index
      @documents = Document.published.notes.order(created_at: :desc)
    end

    def show
      @document = Document.friendly.find(params[:id])
      redirect_to public_posts_path, alert: "Note not found" unless @document.kind == "note" && @document.published?

      @blocks = @document.blocks.order(:position)
    end
  end
end
