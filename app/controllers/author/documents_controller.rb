class Author::DocumentsController < Author::BaseController
  include ToastHelper
  before_action :set_document, only: %i[edit show update destroy publish unpublish remove_portrait]

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
    process_new_tags if params[:new_tags].present?

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
    process_new_tags if params[:new_tags].present?

    if @document.update(doc_params)
      respond_to do |format|
        format.turbo_stream # renders update.turbo_stream.erb
        format.html { redirect_to edit_author_document_path(@document), notice: "Document updated" }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("document_metadata", partial: "form", locals: { document: @document }) }
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @document.destroy
    redirect_to author_documents_path, notice: "Document deleted"
  end

  def publish
    @document.update!(published: true, published_at: Time.current)
    respond_to do |format|
      format.turbo_stream # renders publish.turbo_stream.erb
      format.html { redirect_to author_documents_path, notice: "Published" }
    end
  end

  def unpublish
    @document.update!(published: false)
    respond_to do |format|
      format.turbo_stream # renders unpublish.turbo_stream.erb
      format.html { redirect_to author_documents_path, notice: "Unpublished" }
    end
  end

  def remove_portrait
    @document.portrait.purge
    respond_to do |format|
      format.turbo_stream # renders remove_portrait.turbo_stream.erb
      format.html { redirect_to edit_author_document_path(@document), notice: "Portrait removed" }
    end
  end

  private

  def set_document = @document = Document.friendly.find(params[:id])

  def doc_params
    params.require(:document).permit(
      :kind, :title, :description, :portrait,
      :series_id, :series_position, tag_ids: []
    )
  end

  def process_new_tags
    return unless params[:new_tags].present?

    tag_names = params[:new_tags].split(",").map(&:strip).reject(&:blank?)
    new_tag_ids = tag_names.map do |name|
      Tag.find_or_create_by(title: name).id
    end

    # Merge new tag IDs with existing selected tag IDs
    existing_tag_ids = Array(params.dig(:document, :tag_ids)).reject(&:blank?).map(&:to_i)
    all_tag_ids = (existing_tag_ids + new_tag_ids).uniq

    # Update the params to include all tag IDs
    params[:document][:tag_ids] = all_tag_ids
  end
end
