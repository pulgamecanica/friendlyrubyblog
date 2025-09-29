class Author::BlocksController < Author::BaseController
  before_action :set_document
  before_action :set_block, only: %i[update destroy]

  # POST /author/documents/:document_id/blocks
  # Params:
  #   { block: { type: "MarkdownBlock", position: 0, data: { markdown: "..."} } }
  def create
    @block = @document.blocks.new(permitted_params)
    if @block.save
      respond_to do |format|
        format.turbo_stream # renders create.turbo_stream.erb
        format.html { redirect_to edit_author_document_path(@document), locals: { block: @block } }
      end
    else
      render partial: "author/blocks/form", locals: { document: @document, block: @block }, status: :unprocessable_entity
    end
  end

  def update
    if @block.update(permitted_params)
      respond_to do |format|
        format.turbo_stream # renders update.turbo_stream.erb
        format.html { redirect_to edit_author_document_path(@document) }
      end
    else
      render partial: "author/blocks/form", locals: { document: @document, block: @block }, status: :unprocessable_entity
    end
  end

  def destroy
    @block.destroy
    respond_to do |format|
      format.turbo_stream # renders destroy.turbo_stream.erb
      format.html { redirect_to edit_author_document_path(@document) }
    end
  end

  def preview
    markdown = params[:markdown].to_s
    html = helpers.text_to_markdown(markdown)
    render html: helpers.safe_html(html)
  end

  private

  def set_document = @document = Document.friendly.find(params[:document_id])
  def set_block    = @block    = @document.blocks.find(params[:id])

  def permitted_params
    data = {}
    data["markdown"] = params.dig(:block, :data_markdown)
    data["language"] = params.dig(:block, :data_language)
    data["code"]     = params.dig(:block, :data_code)
    data["html"]     = params.dig(:block, :data_html)

    # Normalize type to known subclasses only (safety)
    {
      type: params.dig(:block, :type),
      position: params.dig(:block, :position),
      data: data.compact_blank
    }
  end
end
