# frozen_string_literal: true

require "net/http"
require "uri"

class Folio::CloudflareStream::Api
  class Error < StandardError; end

  API_BASE_URL = "https://api.cloudflare.com/client/v4"

  def initialize(account_id: nil, api_token: nil, base_url: API_BASE_URL)
    @account_id = account_id.presence || Rails.application.config.folio_cloudflare_stream_account_id
    @api_token = api_token.presence || Rails.application.config.folio_cloudflare_stream_api_token
    @base_url = base_url

    raise Error, "Missing Cloudflare Stream account id" if @account_id.blank?
    raise Error, "Missing Cloudflare Stream API token" if @api_token.blank?
  end

  def copy(url:, meta: {}, allowed_origins: [], require_signed_urls: false)
    body = {
      input: url,
      meta: meta,
      allowedOrigins: Array(allowed_origins).compact_blank.presence,
      requireSignedURLs: require_signed_urls ? true : nil,
    }.compact

    request(:post, "stream/copy", body:)
  end

  def video(identifier)
    request(:get, "stream/#{identifier}")
  end

  def delete(identifier)
    request(:delete, "stream/#{identifier}")
  end

  def signed_url_token(identifier, expires_at:)
    response = request(:post, "stream/#{identifier}/token", body: {
      exp: expires_at.to_i,
    })

    response.fetch("token")
  end

  private
    def request(method, path, body: nil)
      uri = URI.parse("#{@base_url}/accounts/#{@account_id}/#{path}")
      request = request_for(method, uri, body:)
      response = http_for(uri).request(request)
      json = parse_json(response.body)

      unless response.is_a?(Net::HTTPSuccess) && json["success"] != false
        raise Error, error_message(response, json)
      end

      json.fetch("result", json)
    end

    def request_for(method, uri, body:)
      klass = case method
              when :post then Net::HTTP::Post
              when :get then Net::HTTP::Get
              when :delete then Net::HTTP::Delete
              else raise ArgumentError, "Unsupported method #{method}"
      end

      request = klass.new(uri.request_uri)
      request["Accept"] = "application/json"
      request["Authorization"] = "Bearer #{@api_token}"

      if body
        request["Content-Type"] = "application/json"
        request.body = body.to_json
      end

      request
    end

    def http_for(uri)
      Net::HTTP.new(uri.host, uri.port).tap { |http| http.use_ssl = uri.scheme == "https" }
    end

    def parse_json(body)
      JSON.parse(body.presence || "{}")
    rescue JSON::ParserError
      {}
    end

    def error_message(response, json)
      messages = Array(json["errors"]).filter_map { |error| error["message"].presence }
      messages << "HTTP #{response.code}" if messages.blank?
      messages.join(", ")
    end
end
