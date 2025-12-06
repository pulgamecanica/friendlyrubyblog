class Public::SearchController < ApplicationController
  def index
    @query = params[:q].to_s.strip

    @results = if @query.present?
      search_published_documents(@query)
    else
      []
    end

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to root_path }
    end
  end

  private

  def search_published_documents(query)
    # Only search published documents for public access
    Document.published
            .where("title ILIKE ? OR slug ILIKE ? OR description ILIKE ?",
                   "%#{query}%", "%#{query}%", "%#{query}%")
            .order(created_at: :desc)
            .limit(10)
            .map do |doc|
      {
        id: doc.id,
        title: doc.title,
        slug: doc.slug,
        description: doc.description&.truncate(100),
        kind: doc.kind,
        created_at: doc.created_at
      }
    end
  end
end
