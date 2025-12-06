class Author::Analytics::ReferrersSearchController < Author::BaseController
  def index
    @query = params[:q].to_s.strip
    @start_date = params[:start_date]&.to_date
    @end_date = params[:end_date]&.to_date

    @results = if @query.present?
      search_referrers(@query)
    else
      []
    end

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to author_analytics_path }
    end
  end

  private

  def search_referrers(query)
    # Build the base scope
    scope = PageView.where.not(referrer: [ nil, "" ])

    # Apply date range if provided
    if @start_date && @end_date
      scope = scope.where(visited_at: @start_date.beginning_of_day..@end_date.end_of_day)
    end

    # Search referrers by URL pattern
    scope.where("referrer ILIKE ?", "%#{query}%")
         .group(:referrer)
         .order("count_all DESC")
         .limit(15)
         .count
  end
end
