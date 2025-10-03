class CodeExecutionChannel < ApplicationCable::Channel
  def subscribed
    block_id = params[:block_id]

    if block_id.present?
      stream_from "code_execution_#{block_id}"
    else
      reject
    end
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
