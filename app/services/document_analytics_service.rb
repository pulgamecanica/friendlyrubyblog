class DocumentAnalyticsService
  attr_reader :document, :start_date, :end_date

  def initialize(document:, start_date:, end_date:)
    @document = document
    @start_date = start_date
    @end_date = end_date
  end

  def total_views
    page_views_scope.count
  end

  def unique_visitors_count
    page_views_scope.select(:unique_visitor_id).distinct.count
  end

  def average_views_per_day
    days = (end_date.to_date - start_date.to_date).to_i + 1
    return 0 if days.zero?

    (total_views.to_f / days).round(1)
  end

  def views_over_time
    page_views_scope
      .group("DATE(visited_at)")
      .order("DATE(visited_at)")
      .count
      .transform_keys { |date| date.strftime("%b %d") }
  end

  def top_referrers(limit = 10)
    page_views_scope
      .where.not(referrer: [ nil, "" ])
      .group(:referrer)
      .order("count_all DESC")
      .limit(limit)
      .count
  end

  def top_sources(limit = 10)
    page_views_scope
      .where.not(referrer: [ nil, "" ])
      .select("page_views.referrer")
      .distinct
      .map { |pv| extract_domain(pv.referrer) }
      .compact
      .tally
      .sort_by { |_, count| -count }
      .first(limit)
  end

  def device_breakdown
    page_views_scope
      .group(:device)
      .count
  end

  def browser_breakdown
    page_views_scope
      .group(:browser)
      .count
  end

  def os_breakdown
    page_views_scope
      .group(:os)
      .count
  end

  def location_breakdown
    page_views_scope
      .where.not(country: [ "Unknown", nil, "" ])
      .group(:country)
      .order("count_all DESC")
      .limit(10)
      .count
  end

  def recent_views(limit = 50)
    page_views_scope
      .order(visited_at: :desc)
      .limit(limit)
  end

  def top_visitors(limit = 20)
    page_views_scope
      .group(:unique_visitor_id)
      .select("unique_visitor_id, COUNT(*) as view_count, MAX(visited_at) as last_visit")
      .order("view_count DESC")
      .limit(limit)
      .map do |pv|
        {
          visitor_id: pv.unique_visitor_id,
          view_count: pv.view_count,
          last_visit: pv.last_visit
        }
      end
  end

  private

  def page_views_scope
    @page_views_scope ||= PageView
      .where(document: document)
      .where(visited_at: start_date.beginning_of_day..end_date.end_of_day)
  end

  def extract_domain(url)
    return nil if url.blank?

    uri = URI.parse(url)
    uri.host
  rescue URI::InvalidURIError
    nil
  end
end
