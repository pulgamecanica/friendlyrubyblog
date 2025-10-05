require "net/http"
require "json"

class GeoLocationJob < ApplicationJob
  queue_as :default

  # Retry up to 3 times with exponential backoff
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(page_view_id)
    page_view = PageView.find_by(id: page_view_id)
    return unless page_view
    return if page_view.ip_address.blank?

    # Skip if already has location data
    return if page_view.country.present? && page_view.country != "Unknown"

    location_data = fetch_location_data(page_view.ip_address)

    if location_data
      page_view.update_columns(
        country: location_data[:country] || "Unknown",
        city: location_data[:city] || "Unknown"
      )
    end
  rescue StandardError => e
    Rails.logger.error("GeoLocationJob failed for PageView #{page_view_id}: #{e.message}")
    raise
  end

  private

  def fetch_location_data(ip_address)
    # Skip private/local IPs
    return nil if private_ip?(ip_address)

    # Use ip-api.com (free, no API key required, 45 requests/minute)
    uri = URI("http://ip-api.com/json/#{ip_address}?fields=status,country,city")

    response = Net::HTTP.start(uri.host, uri.port, read_timeout: 5, open_timeout: 5) do |http|
      request = Net::HTTP::Get.new(uri)
      http.request(request)
    end

    return nil unless response.is_a?(Net::HTTPSuccess)

    data = JSON.parse(response.body)

    return nil unless data["status"] == "success"

    {
      country: data["country"],
      city: data["city"]
    }
  rescue Net::OpenTimeout, Net::ReadTimeout, JSON::ParserError, SocketError => e
    Rails.logger.warn("Failed to fetch geo location for #{ip_address}: #{e.message}")
    nil
  end

  def private_ip?(ip_address)
    # Check if IP is private/local
    return true if ip_address.blank?
    return true if ip_address == "127.0.0.1"
    return true if ip_address == "::1"
    return true if ip_address.start_with?("192.168.")
    return true if ip_address.start_with?("10.")
    return true if ip_address.match?(/^172\.(1[6-9]|2[0-9]|3[01])\./)

    false
  end
end
