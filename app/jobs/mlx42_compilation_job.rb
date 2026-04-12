class Mlx42CompilationJob < ApplicationJob
  queue_as :default

  def perform(block_id)
    block = Mlx42Block.find(block_id)

    # Set compilation status
    block.data = block.data.to_h.merge(
      "compilation_status" => "compiling",
      "compilation_started_at" => Time.current
    )
    block.save!

    # Compile
    result = Mlx42CompilerService.new(block).compile

    # Update status
    if result[:success]
      block.data = block.data.to_h.merge(
        "compilation_status" => "success",
        "compilation_completed_at" => Time.current
      )
      block.save!
    else
      block.data = block.data.to_h.merge(
        "compilation_status" => "failed",
        "compilation_completed_at" => Time.current
      )
      block.save!
    end

    # If this block belongs to a Game (arcade submission), reflect the
    # compile outcome in the Game's lifecycle state. Blog blocks (owned by
    # a Document) are unaffected — their status is only tracked in
    # block.data["compilation_status"].
    if block.owner.is_a?(Game)
      game = block.owner
      if result[:success]
        game.update!(status: :playable)
      else
        keep_for_review = game.metadata.to_h["keep_for_review_on_failure"]
        next_status     = keep_for_review ? :review : :discarded
        game.update!(
          status:   next_status,
          metadata: game.metadata.to_h.merge("compile_error" => result[:error].to_s)
        )
      end
    end

    # Broadcast update via Turbo Stream
    broadcast_compilation_result(block, result)
  rescue => e
    Rails.logger.error "MLX42 compilation failed: #{e.message}"
    block.data = block.data.to_h.merge(
      "compilation_status" => "error",
      "compilation_error" => e.message
    )
    block.save!
  end

  private

  def broadcast_compilation_result(block, result)
    ActionCable.server.broadcast(
      "mlx42_compilation_#{block.id}",
      {
        status: result[:success] ? "success" : "failed",
        error: result[:error],
        block_id: block.id,
        compilation_status: block.data.to_h["compilation_status"]
      }
    )
  end
end
