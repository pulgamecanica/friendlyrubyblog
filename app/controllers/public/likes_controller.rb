class Public::LikesController < Public::BaseController
  protect_from_forgery with: :exception

  def create
    target = find_target!
    Like.create!(likable: target, actor_hash: current_actor_hash)
    respond_like(target, :created)
  rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
    respond_like(target, :ok) # already liked
  end

  def destroy
    target = find_target!
    Like.where(likable: target, actor_hash: current_actor_hash).delete_all
    respond_like(target, :ok)
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

  def respond_like(target, status_sym)
    respond_to do |format|
      format.html { redirect_back fallback_location: target.is_a?(Document) ? public_document_path(target) : public_document_path(target.document) }
      format.json { render json: { likes_count: target.likes.count }, status: status_sym }
    end
  end
end
