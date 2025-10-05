class VisitorTrackingService
  attr_reader :request, :document, :session

  def initialize(request, document, session)
    @request = request
    @document = document
    @session = session
  end

  def track!
    page_view = PageView.create!(
      document: document,
      ip_address: ip_address,
      country: "Unknown",
      city: "Unknown",
      device: device,
      browser: browser,
      os: os,
      referrer: referrer,
      user_agent: user_agent,
      unique_visitor_id: unique_visitor_id,
      session_id: session_id,
      visited_at: Time.current
    )

    # Queue background job to fetch geo location
    GeoLocationJob.perform_later(page_view.id)

    page_view
  end

  private

  def ip_address
    # Try to get real IP from proxy headers first
    request.headers["X-Forwarded-For"]&.split(",")&.first&.strip ||
      request.headers["X-Real-IP"] ||
      request.remote_ip
  end

  def user_agent
    request.user_agent
  end

  def referrer
    request.referer
  end

  def unique_visitor_id
    # Create a unique ID based on IP and User Agent (persists across sessions)
    session[:unique_visitor_id] ||= Digest::SHA256.hexdigest("#{ip_address}-#{user_agent}")
  end

  def session_id
    session.id&.to_s
  end

  def device
    # Simple device detection from user agent
    ua = user_agent.to_s.downcase
    if ua.match?(/mobile|android|iphone|ipad|ipod/)
      "mobile"
    elsif ua.match?(/tablet|ipad/)
      "tablet"
    else
      "desktop"
    end
  end

  def browser
    ua = user_agent.to_s
    case ua
    when /edg/i then "Edge"
    when /chrome/i then "Chrome"
    when /safari/i then "Safari"
    when /firefox/i then "Firefox"
    when /opera|opr/i then "Opera"
    when /msie|trident/i then "Internet Explorer"
    else "Unknown"
    end
  end

  def os
    ua = user_agent.to_s
    case ua
    when /windows/i then "Windows"
    when /mac/i then "macOS"
    when /linux/i then "Linux"
    when /android/i then "Android"
    when /ios|iphone|ipad/i then "iOS"
    else "Unknown"
    end
  end

end
