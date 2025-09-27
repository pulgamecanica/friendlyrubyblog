class Author::CommentsController < Author::BaseController
  def index
    scope = Comment.order(created_at: :desc)
    scope = scope.where(status: params[:status]) if params[:status].present?
    @comments = scope.limit(200)
  end

  def update
    @comment = Comment.find(params[:id])
    @comment.update!(comment_params)
    respond_to do |f|
      f.turbo_stream
      f.html { redirect_back fallback_location: author_comments_path, notice: "Updated" }
    end
  end

  def destroy
    @comment = Comment.find(params[:id])
    @comment.destroy
    respond_to do |f|
      f.turbo_stream
      f.html { redirect_back fallback_location: author_comments_path, notice: "Deleted" }
    end
  end

  private

  def comment_params
    params.require(:comment).permit(:status)
  end
end
