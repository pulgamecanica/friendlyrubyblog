require "zip/zip"

class Author::BlocksController < Author::BaseController
  before_action :set_document
  before_action :set_block, only: %i[show update destroy remove_image execute toggle_interactive compile_mlx42 import_mlx42_files export_mlx42_files versions preview_version restore_version undo redo]

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

  # GET /author/documents/:document_id/blocks/:id/versions
  def versions
    @versions = @block.versions.reorder(created_at: :desc)
    respond_to do |format|
      format.turbo_stream # renders versions.turbo_stream.erb
      format.html { redirect_to edit_author_document_path(@document) }
    end
  end

  # GET /author/documents/:document_id/blocks/:id/show
  # Returns the block to normal view (exit preview mode)
  def show
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          dom_id(@block),
          partial: "author/blocks/block",
          locals: { block: @block }
        )
      end
      format.html { redirect_to edit_author_document_path(@document) }
    end
  end

  # GET /author/documents/:document_id/blocks/:id/versions/:version_id/preview
  def preview_version
    version = @block.versions.find(params[:version_id])
    @version_block = safe_reify(version) || @block
    @version = version

    respond_to do |format|
      format.turbo_stream # renders preview_version.turbo_stream.erb
      format.html { redirect_to edit_author_document_path(@document) }
    end
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  # PATCH /author/documents/:document_id/blocks/:id/versions/:version_id/restore
  def restore_version
    version = @block.versions.find(params[:version_id])
    version_object = safe_reify(version)

    if version_object
      # Update the block with the version's attributes
      # We need to be careful about which attributes to restore
      attributes_to_restore = version_object.attributes.slice('data', 'type', 'position', 'interactive', 'language_id')

      # Ensure data is a hash (convert from string if needed)
      if attributes_to_restore['data'].is_a?(String)
        attributes_to_restore['data'] = JSON.parse(attributes_to_restore['data'])
      end

      # IMPORTANT: Disable versioning during restore to avoid creating new versions
      success = false
      PaperTrail.request(enabled: false) do
        success = @block.update(attributes_to_restore)
      end

      if success
        respond_to do |format|
          format.turbo_stream # renders restore_version.turbo_stream.erb
          format.html { redirect_to edit_author_document_path(@document) }
        end
      else
        head :unprocessable_entity
      end
    else
      head :not_found
    end
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  # PATCH /author/documents/:document_id/blocks/:id/undo
  def undo
    # PaperTrail stores the BEFORE state in each version
    # So versions.first contains the state before the most recent change
    versions = @block.versions.reorder(created_at: :desc)

    Rails.logger.info "Undo requested for block #{@block.id}, #{versions.count} versions available"

    if versions.count > 0
      # The most recent version's object contains the previous state
      previous_version = versions.first
      version_object = safe_reify(previous_version)

      if version_object
        Rails.logger.info "Restoring attributes from version #{previous_version.id}"
        attributes_to_restore = version_object.attributes.slice('data', 'type', 'position', 'interactive', 'language_id')

        # Ensure data is a hash (convert from string if needed)
        if attributes_to_restore['data'].is_a?(String)
          attributes_to_restore['data'] = JSON.parse(attributes_to_restore['data'])
        end

        # IMPORTANT: Disable versioning during undo to avoid creating new versions
        success = false
        PaperTrail.request(enabled: false) do
          success = @block.update(attributes_to_restore)
        end

        if success
          @message = "Reverted to previous version"
          respond_to do |format|
            format.turbo_stream # renders undo.turbo_stream.erb
            format.html { redirect_to edit_author_document_path(@document) }
          end
        else
          Rails.logger.error "Failed to update block: #{@block.errors.full_messages.join(', ')}"
          head :unprocessable_entity
        end
      else
        Rails.logger.error "Failed to reify version #{previous_version.id}"
        head :not_found
      end
    else
      Rails.logger.warn "No versions available for undo"
      head :not_found
    end
  end

  # PATCH /author/documents/:document_id/blocks/:id/redo
  def redo
    # Redo is complex with PaperTrail and requires tracking current position in version history
    # Since we're now preventing undo from creating new versions, we don't have a natural
    # "forward" history to redo to. This would require session-based undo/redo stack tracking.
    # For now, redo is not supported - use the version history panel to jump to any version.

    Rails.logger.info "Redo requested for block #{@block.id} - not yet implemented"
    head :not_implemented
  end

  private

  def set_document = @document = Document.friendly.find(params[:document_id])
  def set_block    = @block    = @document.blocks.find(params[:id])

  # Helper method to safely reify a version, handling both YAML and JSON serialization
  def safe_reify(version)
    Rails.logger.info "Attempting to reify version #{version.id}, event: #{version.event}"

    # Detect if the object is YAML or JSON
    is_yaml = version.object.to_s.start_with?('---')
    Rails.logger.info "Version #{version.id} appears to be #{is_yaml ? 'YAML' : 'JSON'}"

    begin
      # If it's YAML, manually deserialize with permitted classes
      if is_yaml
        object_data = YAML.safe_load(
          version.object,
          permitted_classes: [
            Symbol,
            Date,
            Time,
            ActiveSupport::TimeWithZone,
            ActiveSupport::TimeZone,
            ActiveSupport::HashWithIndifferentAccess,
            BigDecimal
          ],
          aliases: true
        )

        if object_data.is_a?(Hash)
          obj = @block.class.new(object_data)
          Rails.logger.info "Successfully reified YAML version #{version.id}"
          return obj
        end
      else
        # Try JSON deserialization
        version_object = version.reify
        if version_object
          Rails.logger.info "Successfully reified JSON version #{version.id}"
          return version_object
        end
      end
    rescue Psych::DisallowedClass => e
      Rails.logger.error "YAML deserialization blocked: #{e.message}"
    rescue JSON::ParserError => e
      Rails.logger.error "JSON parsing failed: #{e.message}"
    rescue => e
      Rails.logger.error "Failed to reify version: #{e.class.name} - #{e.message}"
      Rails.logger.error e.backtrace.first(5).join("\n")
    end

    Rails.logger.error "All reification attempts failed for version #{version.id}"
    nil
  end

  def permitted_params
    data = {}
    data["markdown"] = params.dig(:block, :data_markdown)
    data["language"] = params.dig(:block, :data_language)
    data["code"]     = params.dig(:block, :data_code)
    data["html"]     = params.dig(:block, :data_html)
    data["caption"]  = params.dig(:block, :data_caption)
    data["filename"] = params.dig(:block, :data_filename)
    data["text"]     = params.dig(:block, :text)

    # Handle MLX42 multi-file support
    if params.dig(:block, :data_files).present?
      begin
        data["files"] = JSON.parse(params.dig(:block, :data_files))
      rescue JSON::ParserError
        # If parsing fails, keep empty
        data["files"] = []
      end
    end

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
