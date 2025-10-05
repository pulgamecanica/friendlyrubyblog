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
