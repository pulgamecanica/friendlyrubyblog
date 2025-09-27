class Public::CommentsController < Public::BaseController
  protect_from_forgery with: :exception

  def create
    target  = find_target!
    comment = target.comments.new(comment_params)
    comment.actor_hash      = current_actor_hash
    comment.ip_hash         = ip_hash
    comment.user_agent_hash = user_agent_hash
    comment.status          = "visible" # in the future we can change to pending for moderation...

    if comment.save
      redirect_back fallback_location: fallback_path_for(target), notice: "Comment posted."
    else
      redirect_back fallback_location: fallback_path_for(target), alert: comment.errors.full_messages.to_sentence
    end
  end

  private

  def find_target!
    if params[:document_id]
      Document.friendly.find(params[:document_id])
    elsif params[:block_id]
      Block.find(params[:block_id])
    else
      raise ActiveRecord::RecordNotFound
    end
  end

  def fallback_path_for(target)
    target.is_a?(Document) ? public_document_path(target) : public_document_path(target.document)
  end

  def comment_params
    params.require(:comment).permit(:name, :email, :website, :body_markdown, :parent_id, :block_line_start, :block_line_end)
  end
end
