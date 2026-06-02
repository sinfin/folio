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
  Model = Struct.new(:id, :label, :created_at, :metadata, keyword_init: true)

  class << self
    def list_models(api_key:, timeout: Folio::Ai::Providers::Base::DEFAULT_TIMEOUT)
      raise NotImplementedError, "#{name} must implement .list_models"
    end

    def perform_get(uri:, headers:, timeout:)
      http = build_http(uri:, timeout:)
      request = Net::HTTP::Get.new(uri)
      headers.each { |key, value| request[key] = value }

      handle_response(http.request(request))
    rescue *TIMEOUT_ERRORS
      raise Folio::Ai::ProviderTimeoutError, "AI provider request timed out"
    rescue *NETWORK_ERRORS => e
      raise Folio::Ai::ProviderError, "AI provider request failed: #{e.class.name}"
    end

    def handle_response(response)
      return response.body if response.is_a?(Net::HTTPSuccess)
      raise Folio::Ai::ProviderRateLimitError, "AI provider rate limit reached" if response.code.to_i == 429
      raise Folio::Ai::ProviderModelUnavailableError, "AI provider model is unavailable" if model_unavailable_response?(response)

      raise Folio::Ai::ProviderError, "AI provider request failed with HTTP #{response.code}"
    end

    private
      def build_http(uri:, timeout:)
        Net::HTTP.new(uri.host, uri.port).tap do |http|
          http.use_ssl = uri.scheme == "https"
          http.open_timeout = timeout
          http.read_timeout = timeout
          http.write_timeout = timeout if http.respond_to?(:write_timeout=)
          http.max_retries = 0 if http.respond_to?(:max_retries=)
        end
      end

      def model_unavailable_response?(response)
        return false unless [400, 404].include?(response.code.to_i)

        error_text = parsed_error_text(response.body)
        error_text.match?(/model.*(not found|unavailable|does not exist|invalid|not supported)/) ||
          error_text.match?(/(model_not_found|not_found_error|invalid_model)/)
      end

      def parsed_error_text(body)
        parsed = JSON.parse(body.to_s)
        error = parsed["error"]

        [
          error.is_a?(Hash) ? error["code"] : nil,
          error.is_a?(Hash) ? error["type"] : nil,
          error.is_a?(Hash) ? error["message"] : nil,
          parsed["message"],
        ].compact.join(" ").downcase
      rescue JSON::ParserError
        body.to_s.downcase
      end
  end

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
      http = self.class.send(:build_http, uri: request.uri, timeout:)

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
      self.class.handle_response(response)
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
