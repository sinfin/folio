# frozen_string_literal: true

require "net/http"
require "uri"

class Folio::CloudflareStream::Api
  class Error < StandardError
    attr_reader :status_code

    def initialize(message, status_code: nil)
      @status_code = status_code

      super(message)
    end

    def not_found?
      status_code == 404
    end

    def retryable?
      status_code.blank? || status_code == 408 || status_code == 429 || status_code >= 500
    end
  end

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
        raise Error.new(error_message(response, json), status_code: response.code.to_i)
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
      Net::HTTP.new(uri.host, uri.port).tap do |http|
        http.use_ssl = uri.scheme == "https"
        http.open_timeout = Rails.application.config.folio_cloudflare_stream_api_open_timeout
        http.read_timeout = Rails.application.config.folio_cloudflare_stream_api_read_timeout
        http.write_timeout = Rails.application.config.folio_cloudflare_stream_api_write_timeout if http.respond_to?(:write_timeout=)
      end
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
