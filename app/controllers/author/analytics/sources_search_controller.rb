class Author::Analytics::SourcesSearchController < Author::BaseController
  def index
    @query = params[:q].to_s.strip
    @start_date = params[:start_date]&.to_date
    @end_date = params[:end_date]&.to_date

    @results = if @query.present?
      search_sources(@query)
    else
      []
    end

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to author_analytics_path }
    end
  end

  private

  def search_sources(query)
    # Build the base scope
    scope = PageView.where.not(referrer: [ nil, "" ])

    # Apply date range if provided
    if @start_date && @end_date
      scope = scope.where(visited_at: @start_date.beginning_of_day..@end_date.end_of_day)
    end

    # Search referrers and extract domains
    referrers = scope.where("referrer ILIKE ?", "%#{query}%")
                    .select(:referrer)
                    .distinct
                    .pluck(:referrer)

    # Extract domains and tally
    referrers.map { |url| extract_domain(url) }
             .compact
             .tally
             .sort_by { |_, count| -count }
             .first(15)
  end

  def extract_domain(url)
    return nil if url.blank?

    uri = URI.parse(url)
    uri.host
  rescue URI::InvalidURIError
    nil
  end
end
