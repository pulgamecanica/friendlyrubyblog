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

  def sort
    block_ids = params[:block_ids]

    if block_ids.present? && block_ids.is_a?(Array)
      # Disable callbacks to prevent position shifting during bulk update
      Block.transaction do
        block_ids.each_with_index do |block_id, index|
          block = @document.blocks.find(block_id)
          # Use update_column to bypass callbacks and validations
          block.update_column(:position, index + 1)
        end
      end

      render json: { success: true, message: "Blocks reordered successfully" }
    else
      render json: { success: false, error: "Invalid block_ids parameter" }, status: :bad_request
    end
  rescue ActiveRecord::RecordNotFound => e
    render json: { success: false, error: "Block not found: #{e.message}" }, status: :not_found
  rescue => e
    render json: { success: false, error: "Failed to reorder blocks: #{e.message}" }, status: :internal_server_error
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
