# frozen_string_literal: true

class PurgeCloudflareCacheJob < ApplicationJob
  queue_as :default

  def perform(urls)
    zone_id = ENV["CLOUDFLARE_ZONE_ID"]
    api_token = ENV["CLOUDFLARE_API_TOKEN"]

    return unless zone_id.present? && api_token.present?

    conn = Faraday.new(url: "https://api.cloudflare.com") do |f|
      f.request :json
      f.response :json
      f.adapter :net_http
    end

    response = conn.post("/client/v4/zones/#{zone_id}/purge_cache") do |req|
      req.headers["Authorization"] = "Bearer #{api_token}"
      req.body = { files: Array(urls) }
    end

    unless response.success?
      Rails.logger.error("Cloudflare cache purge failed: #{response.body}")
    end
  end
end
