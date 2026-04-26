# frozen_string_literal: true

require "net/http"
require "openssl"

module Folio::Ai::Providers
end

class Folio::Ai::Providers::Base
  DEFAULT_TIMEOUT = 30
  TIMEOUT_ERRORS = [
    Net::OpenTimeout,
    Net::ReadTimeout,
    (Net::WriteTimeout if defined?(Net::WriteTimeout)),
  ].compact.freeze
  NETWORK_ERRORS = [
    EOFError,
    SocketError,
    Errno::ECONNREFUSED,
    Errno::ECONNRESET,
    Errno::EHOSTUNREACH,
    Errno::ENETUNREACH,
    Net::HTTPBadResponse,
    Net::HTTPHeaderSyntaxError,
    Net::ProtocolError,
    (OpenSSL::SSL::SSLError if defined?(OpenSSL::SSL::SSLError)),
  ].compact.freeze

  Request = Struct.new(:uri, :headers, :body, keyword_init: true)

  def initialize(api_key:, model:, timeout: DEFAULT_TIMEOUT)
    raise ArgumentError, "AI provider API key is blank" if api_key.blank?
    raise ArgumentError, "AI provider model is blank" if model.blank?

    @api_key = api_key
    @model = model
    @timeout = timeout
  end

  def build_request(prompt:, field:, suggestion_count:)
    raise NotImplementedError, "#{self.class.name} must implement #build_request"
  end

  def generate_suggestions(prompt:, field:, suggestion_count: Folio::Ai::ResponseNormalizer::DEFAULT_SUGGESTION_COUNT)
    request = build_request(prompt:, field:, suggestion_count:)
    response_body = perform_request(request)

    normalize_response(response_body:, field:, suggestion_count:)
  end

  def normalize_response(response_body:, field:, suggestion_count:)
    Folio::Ai::ResponseNormalizer.new(raw_response: extract_response_text(response_body),
                                      field:,
                                      suggestion_count:).call
  end

  private
    attr_reader :api_key,
                :model,
                :timeout

    def endpoint
      raise NotImplementedError, "#{self.class.name} must implement #endpoint"
    end

    def perform_request(request)
      http = Net::HTTP.new(request.uri.host, request.uri.port)
      http.use_ssl = request.uri.scheme == "https"
      http.open_timeout = timeout
      http.read_timeout = timeout
      http.write_timeout = timeout if http.respond_to?(:write_timeout=)
      http.max_retries = 0 if http.respond_to?(:max_retries=)

      response = http.request(build_http_request(request))
      handle_response(response)
    rescue *TIMEOUT_ERRORS
      raise Folio::Ai::ProviderTimeoutError, "AI provider request timed out"
    rescue *NETWORK_ERRORS => e
      raise Folio::Ai::ProviderError, "AI provider request failed: #{e.class.name}"
    end

    def build_http_request(request)
      Net::HTTP::Post.new(request.uri).tap do |http_request|
        request.headers.each { |key, value| http_request[key] = value }
        http_request.body = JSON.generate(request.body)
      end
    end

    def handle_response(response)
      return response.body if response.is_a?(Net::HTTPSuccess)
      raise Folio::Ai::ProviderRateLimitError, "AI provider rate limit reached" if response.code.to_i == 429

      raise Folio::Ai::ProviderError, "AI provider request failed with HTTP #{response.code}"
    end

    def extract_response_text(response_body)
      response_body
    end

    def json_schema_instruction(suggestion_count)
      <<~TEXT.squish
        Return only valid JSON with a top-level "suggestions" array.
        Generate #{suggestion_count} suggestions.
        Each suggestion must contain "text" and may contain "key" and "meta".
      TEXT
    end
end
