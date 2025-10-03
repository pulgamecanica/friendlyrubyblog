class CodeExecutionJob < ApplicationJob
  queue_as :default

  def perform(block_id, code)
    block = Block.find(block_id)

    unless block.is_a?(CodeBlock) && block.supports_execution?
      Rails.logger.error "Block #{block_id} does not support execution"
      return
    end

    begin
      # Execute the code using the service
      result = CodeExecutionService.execute(
        code: code,
        language: block.language.name.downcase,
        executable_command: block.language.executable_command
      )

      # Store result in block data
      block.set_execution_result(result.merge(status: 'completed', executed_at: Time.current))
      block.save!

      # Broadcast the result to the user via ActionCable
      ActionCable.server.broadcast(
        "code_execution_#{block_id}",
        {
          status: 'completed',
          output: result[:output],
          error: result[:error],
          execution_time: result[:execution_time],
          block_id: block_id
        }
      )

    rescue => e
      Rails.logger.error "Code execution failed for block #{block_id}: #{e.message}"

      # Store error result
      error_result = {
        status: 'failed',
        error: e.message,
        executed_at: Time.current
      }

      block.set_execution_result(error_result)
      block.save!

      # Broadcast error
      ActionCable.server.broadcast(
        "code_execution_#{block_id}",
        {
          status: 'failed',
          error: e.message,
          block_id: block_id
        }
      )
    end
  end
end
