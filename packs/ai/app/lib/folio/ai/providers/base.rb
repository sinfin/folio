# frozen_string_literal: true

# Shared provider behavior for model defaults, timeouts, and JSON HTTP requests.
require "net/http"

module Folio::Ai::Providers
end

class Folio::Ai::Providers::Base
  def self.key
    name.demodulize.underscore.to_sym
  end

  def self.available?
    false
  end

  def self.default_model
    models.first
  end

  def self.models
    [const_get(:DEFAULT_MODEL)]
  end

  attr_reader :model

  def initialize(model: nil, timeout_ms: Folio::Ai.config.client_request_timeout_ms)
    @model = model.presence || default_model
    @timeout_ms = timeout_ms
  end

  def complete(prompt:, suggestion_count:)
    raise NotImplementedError, "#{self.class.name} must implement #complete"
  end

  private
    attr_reader :timeout_ms

    def default_model
      self.class.default_model
    end

    def post_json(uri:, headers:, body:)
      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      headers.each { |key, value| request[key] = value }
      request.body = JSON.generate(body)

      response = build_http(uri).request(request)
      raise Folio::Ai::ProviderError, "AI provider request failed with HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body.to_s)
    rescue JSON::ParserError
      raise Folio::Ai::ProviderError, "AI provider response is not valid JSON"
    rescue Net::OpenTimeout, Net::ReadTimeout
      raise Folio::Ai::ProviderError, "AI provider request timed out"
    rescue EOFError, SocketError, SystemCallError, Net::HTTPError => e
      raise Folio::Ai::ProviderError, "AI provider request failed: #{e.class.name}"
    end

    def build_http(uri)
      Net::HTTP.new(uri.host, uri.port).tap do |http|
        http.use_ssl = uri.scheme == "https"
        http.open_timeout = timeout_seconds
        http.read_timeout = timeout_seconds
        http.write_timeout = timeout_seconds if http.respond_to?(:write_timeout=)
        http.max_retries = 0 if http.respond_to?(:max_retries=)
      end
    end

    def timeout_seconds
      timeout = timeout_ms.to_i
      timeout.positive? ? timeout / 1000.0 : 45
    end
end
