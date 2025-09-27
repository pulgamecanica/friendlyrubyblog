class Author::DocumentsController < Author::BaseController
  before_action :set_document, only: %i[edit show update destroy publish unpublish]

  def index
    @recent_documents = Document.order(updated_at: :desc).limit(10)
    @recent_series    = Series.order(updated_at: :desc).limit(5)
    @recent_comments  = Comment.order(created_at: :desc).limit(5)
  end

  def show
  end

  def new
    @document = Document.new(kind: "post", published: false)
  end

  def create
    @document = current_author.documents.build(doc_params)
    @document.kind ||= "post"
    if @document.save
      redirect_to edit_author_document_path(@document), notice: "Document created"
    else
      Rails.logger.debug(@document.errors.full_messages.join(", "))
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @blocks = @document.blocks
  end

  def update
    if @document.update(doc_params)
      redirect_to edit_author_document_path(@document), notice: "Document updated"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @document.destroy
    redirect_to author_documents_path, notice: "Document deleted"
  end

  def publish
    @document.update!(published: true, published_at: Time.current)
    redirect_to author_documents_path, notice: "Published"
  end

  def unpublish
    @document.update!(published: false)
    redirect_to author_documents_path, notice: "Unpublished"
  end

  private

  def set_document = @document = Document.friendly.find(params[:id])

  def doc_params
    params.require(:document).permit(
      :kind, :title, :description, :published, :published_at,
      :series_id, :series_position, tag_ids: []
    )
  end
end
