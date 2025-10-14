class AnalyticsService
  attr_reader :start_date, :end_date, :author

  def initialize(start_date: 30.days.ago, end_date: Time.current)
    @start_date = start_date.beginning_of_day
    @end_date = end_date.end_of_day
  end

  def page_views_scope
    PageView.joins(:document)
                    .where("page_views.visited_at BETWEEN ? AND ?", start_date, end_date)
  end

  # Top documents by views
  def top_documents(limit = 10)
    page_views_scope
      .group("documents.id", "documents.title", "documents.slug")
      .select("documents.title, documents.slug, COUNT(page_views.id) as view_count")
      .order("view_count DESC")
      .limit(limit)
      .map { |result| { title: result.title, slug: result.slug, views: result.view_count } }
  end

  # Top referrers
  def top_referrers(limit = 10)
    page_views_scope
      .where.not(referrer: [ nil, "" ])
      .group(:referrer)
      .order("count_all DESC")
      .limit(limit)
      .count
  end

  # Top sources (domains from referrers)
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
      .to_h
  end

  # Top next pages (where visitors went after)
  def top_next_pages(limit = 10)
    page_views_scope
      .where.not(next_page: [ nil, "" ])
      .group(:next_page)
      .order("count_all DESC")
      .limit(limit)
      .count
  end

  # Views over time (daily breakdown)
  def views_over_time
    page_views_scope
      .group("DATE(page_views.visited_at)")
      .order("DATE(page_views.visited_at)")
      .count
      .transform_keys { |date| date.to_s }
  end

  # Unique visitors count
  def unique_visitors_count
    page_views_scope.distinct.count(:unique_visitor_id)
  end

  # Total views count
  def total_views
    page_views_scope.count
  end

  # Top countries
  def top_countries(limit = 10)
    page_views_scope
      .where.not(country: [ "Unknown", nil, "" ])
      .group(:country)
      .order("count_all DESC")
      .limit(limit)
      .count
  end

  # Device breakdown
  def device_breakdown
    page_views_scope.group(:device).count
  end

  # Browser breakdown
  def browser_breakdown
    page_views_scope.group(:browser).count
  end

  # OS breakdown
  def os_breakdown
    page_views_scope.group(:os).count
  end

  # Top visitors (by view count)
  def top_visitors(limit = 20)
    page_views_scope
      .group(:unique_visitor_id)
      .select("unique_visitor_id, COUNT(*) as view_count, MAX(visited_at) as last_visit")
      .order("view_count DESC")
      .limit(limit)
      .map do |result|
        {
          visitor_id: result.unique_visitor_id,
          view_count: result.view_count,
          last_visit: result.last_visit
        }
      end
  end

  # Get visitor activity
  def visitor_activity(visitor_id)
    page_views_scope
      .where(unique_visitor_id: visitor_id)
      .includes(:document)
      .order(visited_at: :desc)
  end

  # Get visitor info
  def visitor_info(visitor_id)
    first_view = page_views_scope.where(unique_visitor_id: visitor_id).order(:visited_at).first
    return nil unless first_view

    {
      visitor_id: visitor_id,
      first_visit: first_view.visited_at,
      country: first_view.country,
      city: first_view.city,
      device: first_view.device,
      browser: first_view.browser,
      os: first_view.os,
      ip_address: first_view.ip_address,
      total_views: page_views_scope.where(unique_visitor_id: visitor_id).count,
      unique_pages: page_views_scope.where(unique_visitor_id: visitor_id).distinct.count(:document_id)
    }
  end

  # Recent page views
  def recent_views(limit = 50)
    page_views_scope
      .includes(:document)
      .order(visited_at: :desc)
      .limit(limit)
  end

  # Average views per day
  def average_views_per_day
    days = ((end_date - start_date) / 1.day).ceil
    return 0 if days.zero?

    (total_views.to_f / days).round(2)
  end

  private

  def extract_domain(url)
    return nil if url.blank?

    uri = URI.parse(url)
    uri.host
  rescue URI::InvalidURIError
    nil
  end
end
