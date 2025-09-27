class Author::CommentsController < Author::BaseController
  def index
    @comments = Comment.order(created_at: :desc).limit(200)
  end

  def update
    comment = Comment.find(params[:id])
    if comment.update(comment_params)
      redirect_back fallback_location: author_comments_path, notice: "Comment updated"
    else
      redirect_back fallback_location: author_comments_path, alert: comment.errors.full_messages.to_sentence
    end
  end

  def destroy
    Comment.find(params[:id]).destroy
    redirect_back fallback_location: author_comments_path, notice: "Comment deleted"
  end

  private

  def comment_params
    params.require(:comment).permit(:status)
  end
end
