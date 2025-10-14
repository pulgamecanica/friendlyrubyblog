class Author::AnalyticsController < Author::BaseController
  def index
    @start_date = params[:start_date]&.to_date || 30.days.ago
    @end_date = params[:end_date]&.to_date || Date.today

    @analytics = AnalyticsService.new(
      start_date: @start_date,
      end_date: @end_date
    )
  end

  def visitor
    @visitor_id = params[:id]
    @start_date = params[:start_date]&.to_date || 30.days.ago
    @end_date = params[:end_date]&.to_date || Date.today

    @analytics = AnalyticsService.new(
      start_date: @start_date,
      end_date: @end_date
    )

    @visitor_info = @analytics.visitor_info(@visitor_id)
    @visitor_activity = @analytics.visitor_activity(@visitor_id)

    redirect_to author_analytics_path, alert: "Visitor not found" unless @visitor_info
  end
end
