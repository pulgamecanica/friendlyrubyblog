class Author::Documents::SearchController < Author::BaseController
  def index
    @query = params[:q].to_s.strip
    @start_date = params[:start_date]&.to_date
    @end_date = params[:end_date]&.to_date

    @results = if @query.present?
      search_documents(@query)
    else
      []
    end

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to author_analytics_path }
    end
  end

  private

  def search_documents(query)
    # Search documents by title or slug
    documents = Document.where("title ILIKE ? OR slug ILIKE ?", "%#{query}%", "%#{query}%")
                        .order(created_at: :desc)
                        .limit(10)

    # Get analytics data for each document within the date range
    documents.map do |doc|
      views_count = if @start_date && @end_date
        PageView.where(document: doc)
                .where(visited_at: @start_date.beginning_of_day..@end_date.end_of_day)
                .count
      else
        PageView.where(document: doc).count
      end

      {
        id: doc.id,
        title: doc.title,
        slug: doc.slug,
        views: views_count,
        created_at: doc.created_at,
        published: doc.published
      }
    end
  end
end
