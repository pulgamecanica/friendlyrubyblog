require "zip/zip"

class Author::BlocksController < Author::BaseController
  before_action :set_document
  before_action :set_block, only: %i[update destroy remove_image execute toggle_interactive compile_mlx42 import_mlx42_files export_mlx42_files]

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
    # Handle image appending for ImageBlock
    if @block.is_a?(ImageBlock) && params.dig(:block, :images).present?
      params[:block][:images].each do |image|
        @block.images.attach(image) if image.present?
      end
    end

    # Handle asset appending for Mlx42Block
    if @block.is_a?(Mlx42Block) && params.dig(:block, :assets).present?
      params[:block][:assets].each do |asset|
        # Only attach if the asset is actually a file (not blank/empty)
        @block.assets.attach(asset) if asset.present? && asset.is_a?(ActionDispatch::Http::UploadedFile)
      end
    end

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

  def remove_image
    attachment = @block.images.attachments.find(params[:attachment_id])
    attachment.purge
    respond_to do |format|
      format.turbo_stream # renders remove_image.turbo_stream.erb
      format.html { redirect_to edit_author_document_path(@document) }
    end
  end

  def preview
    markdown = params[:markdown].to_s
    html = helpers.text_to_markdown(markdown)
    render html: helpers.safe_html(html)
  end

  def toggle_interactive
    unless @block.is_a?(CodeBlock) && @block.can_be_interactive?
      head :unprocessable_entity
      return
    end

    # Just toggle the interactive field, don't touch anything else
    @block.update_column(:interactive, !@block.interactive?)

    # Return minimal response - just update the toolbar
    respond_to do |format|
      format.turbo_stream # renders toggle_interactive.turbo_stream.erb
      format.json { render json: { interactive: @block.interactive? } }
    end
  end

  def execute
    unless @block.is_a?(CodeBlock) && @block.supports_execution?
      render json: { error: "Block does not support code execution" }, status: :unprocessable_entity
      return
    end

    code = params[:code].to_s

    if code.blank?
      render json: { error: "No code provided" }, status: :unprocessable_entity
      return
    end

    begin
      # Mark execution as running
      @block.set_execution_result({
        status: "running",
        started_at: Time.current
      })
      @block.save!

      # Queue the job for async execution
      CodeExecutionJob.perform_later(@block.id, code)

      render json: {
        status: "queued",
        message: "Code execution started",
        block_id: @block.id
      }

    rescue => e
      Rails.logger.error "Failed to queue code execution: #{e.message}"
      render json: { error: "Failed to start execution: #{e.message}" }, status: :internal_server_error
    end
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

  def compile_mlx42
    unless @block.is_a?(Mlx42Block)
      render json: { error: "Block is not an MLX42 block" }, status: :unprocessable_entity
      return
    end

    begin
      # Mark compilation as starting
      @block.data = @block.data.to_h.merge(
        "compilation_status" => "queued",
        "compilation_queued_at" => Time.current
      )
      @block.save!

      # Queue the job for async compilation
      Mlx42CompilationJob.perform_later(@block.id)

      render json: {
        status: "queued",
        message: "Compilation started",
        block_id: @block.id
      }
    rescue => e
      Rails.logger.error "Failed to queue MLX42 compilation: #{e.message}"
      render json: { error: "Failed to start compilation: #{e.message}" }, status: :internal_server_error
    end
  end

  def export_mlx42_files
    unless @block.is_a?(Mlx42Block)
      render json: { error: "Block is not an MLX42 block" }, status: :unprocessable_entity
      return
    end

    begin
      # Create a temporary zip in memory
      temp_zip = Tempfile.new([ "mlx42_block_#{@block.id}", ".zip" ])
      Zip::OutputStream.open(temp_zip) do |zip|
        if @block.js_file.attached?
          zip.put_next_entry("mlx42_output.js")
          zip.write @block.js_file.download
        end

        if @block.wasm_file.attached?
          zip.put_next_entry("mlx42_output.wasm")
          zip.write @block.wasm_file.download
        end

        if @block.data_file.attached?
          zip.put_next_entry("mlx42_output.data")
          zip.write @block.data_file.download
        end
      end

      temp_zip.rewind

      # Create a temporary Active Storage blob (expires automatically)
      blob = ActiveStorage::Blob.create_and_upload!(
        io: temp_zip,
        filename: "mlx42_block_#{@block.id}.zip",
        content_type: "application/zip"
      )

      # Generate a short-lived URL (10 minutes)
      ActiveStorage::Current.url_options = { host: request.base_url }
      url = blob.url(expires_in: 10.minutes, disposition: "attachment")

      render json: { status: "success", url: url }
    ensure
      temp_zip.close
      temp_zip.unlink
    end
  end

  def import_mlx42_files
    unless @block.is_a?(Mlx42Block)
      render json: { error: "Block is not an MLX42 block" }, status: :unprocessable_entity
      return
    end

    begin
      # Attach the files
      if params[:js_file].present?
        @block.js_file.purge if @block.js_file.attached?
        @block.js_file.attach(params[:js_file])
      end

      if params[:wasm_file].present?
        @block.wasm_file.purge if @block.wasm_file.attached?
        @block.wasm_file.attach(params[:wasm_file])
      end

      if params[:data_file].present?
        @block.data_file.purge if @block.data_file.attached?
        @block.data_file.attach(params[:data_file])
      end

      # Update compilation status
      @block.data = @block.data.to_h.merge(
        "compilation_status" => "imported",
        "compilation_completed_at" => Time.current
      )
      @block.save!

      render json: {
        status: "success",
        message: "Files imported successfully",
        block_id: @block.id
      }
    rescue => e
      Rails.logger.error "Failed to import MLX42 files: #{e.message}"
      render json: { error: "Failed to import files: #{e.message}" }, status: :internal_server_error
    end
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
    data["caption"]  = params.dig(:block, :data_caption)
    data["filename"] = params.dig(:block, :data_filename)
    data["text"]     = params.dig(:block, :text)

    block_params = {
      type: params.dig(:block, :type),
      position: params.dig(:block, :position),
      data: data.compact_blank,
      language_id: params.dig(:block, :language_id)
    }

    # Handle images for ImageBlock (append, don't replace)
    if params.dig(:block, :type) == "ImageBlock" && params.dig(:block, :images).present?
      # Don't add to block_params, handle separately to append
    end

    # Handle assets for Mlx42Block (append, don't replace)
    if params.dig(:block, :type) == "Mlx42Block" && params.dig(:block, :assets).present?
      # Don't add to block_params, handle separately to append
    end

    # For CodeBlocks, handle language assignment by name for backward compatibility
    if params.dig(:block, :type) == "CodeBlock" && params.dig(:block, :language_name).present?
      language = Language.find_or_create_by_name(params.dig(:block, :language_name))
      block_params[:language_id] = language&.id
      block_params[:interactive] = if @block.nil? then false else @block.interactive? end
      data["language"] = params.dig(:block, :language_name)
    end

    block_params[:data] = data.compact_blank

    # Don't use compact_blank on block_params because it removes false values
    # and we need to be able to set interactive: false
    block_params.compact { |key, value| value.nil? }
  end
end
