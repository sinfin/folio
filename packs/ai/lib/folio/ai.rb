# frozen_string_literal: true

module Folio::Ai
  DEFAULT_OPENAI_MODEL = "gpt-5.5"
  DEFAULT_ANTHROPIC_MODEL = "claude-opus-4-7"
  DEFAULT_PROVIDER_MODELS = {
    openai: DEFAULT_OPENAI_MODEL,
    anthropic: DEFAULT_ANTHROPIC_MODEL,
  }.freeze
  PACK_ASSETS = {
    javascripts: %w[folio_pack_ai],
    stylesheets: %w[folio_pack_ai],
  }.freeze

  Error = Class.new(StandardError)
  UnknownProviderError = Class.new(Error)
  ProviderError = Class.new(Error)
  ProviderTimeoutError = Class.new(ProviderError)
  ProviderRateLimitError = Class.new(ProviderError)
  ProviderModelUnavailableError = Class.new(ProviderError)
  ResponseInvalidError = Class.new(Error)
  CostLimitExceededError = Class.new(Error)
  RateLimitExceededError = Class.new(Error)

  TRACKING_PAYLOAD_KEYS = %i[
    site_id
    user_id
    integration_key
    field_key
    provider
    model
    requested_model
    fallback_model
    suggestion_count
    latency_ms
    error_code
    warning_code
    record_class
  ].freeze

  class << self
    attr_accessor :enabled,
                  :default_provider,
                  :model_fallback_enabled,
                  :provider_request_storage,
                  :max_prompt_chars,
                  :rate_limit

    attr_writer :provider_model_options,
                :model_catalog_cache_ttl,
                :provider_request_timeout,
                :client_request_timeout_ms

    def configure
      yield self
    end

    def reset_configuration!
      self.enabled = false
      self.default_provider = :openai
      self.provider_models = DEFAULT_PROVIDER_MODELS
      self.provider_model_options = {}
      self.model_catalog_cache_ttl = 1.hour
      self.model_fallback_enabled = true
      self.provider_request_storage = false
      self.provider_request_timeout = 30
      self.client_request_timeout_ms = 45_000
      self.max_prompt_chars = 80_000
      self.rate_limit = nil
    end

    def provider_models=(value)
      @provider_models = (value || {}).to_h
    end

    def registry
      @registry ||= Folio::Ai::Registry.new
    end

    def reset_registry!
      @registry = Folio::Ai::Registry.new
    end

    def register_integration(...)
      registry.register_integration(...)
    end

    def pack_assets
      PACK_ASSETS
    end

    def enabled?
      ActiveModel::Type::Boolean.new.cast(enabled) && !env_disabled?
    end

    def env_disabled?
      ENV["FOLIO_AI_DISABLED"].present?
    end

    def default_model(provider)
      provider_models.fetch(provider.to_sym)
    end

    def provider_models
      (@provider_models || {}).to_h.transform_keys(&:to_sym)
    end

    def provider_model_options
      @provider_model_options || {}
    end

    def known_provider?(provider)
      provider_models.key?(provider.to_sym)
    end

    def provider_adapter(provider:, model: default_model(provider), api_key: nil)
      provider_adapter_class(provider).new(api_key: api_key || provider_api_key(provider),
                                           model:,
                                           timeout: provider_request_timeout)
    end

    def provider_request_timeout
      positive_config_value(@provider_request_timeout, 30)
    end

    def client_request_timeout_ms
      positive_config_value(@client_request_timeout_ms, 45_000)
    end

    def model_catalog_cache_ttl
      value = @model_catalog_cache_ttl

      value.respond_to?(:to_i) && value.to_i.positive? ? value : 1.hour
    end

    def model_fallback_enabled?
      ActiveModel::Type::Boolean.new.cast(model_fallback_enabled)
    end

    def provider_request_storage?
      ActiveModel::Type::Boolean.new.cast(provider_request_storage)
    end

    def provider_adapter_class(provider)
      case provider.to_sym
      when :openai
        Folio::Ai::Providers::OpenAi
      when :anthropic
        Folio::Ai::Providers::Anthropic
      else
        raise Folio::Ai::UnknownProviderError, "Unknown AI provider: #{provider}"
      end
    end

    def provider_api_key(provider)
      case provider.to_sym
      when :openai
        ENV.fetch("OPENAI_API_KEY") { raise ArgumentError, "OPENAI_API_KEY is not configured" }
      when :anthropic
        ENV.fetch("ANTHROPIC_API_KEY") { raise ArgumentError, "ANTHROPIC_API_KEY is not configured" }
      else
        raise Folio::Ai::UnknownProviderError, "Unknown AI provider: #{provider}"
      end
    end

    def track(event, payload = {})
      ActiveSupport::Notifications.instrument("folio.ai.#{event}",
                                              sanitized_tracking_payload(payload))
    rescue StandardError
      nil
    end

    private
      def sanitized_tracking_payload(payload)
        payload.symbolize_keys.slice(*TRACKING_PAYLOAD_KEYS)
      end

      def positive_config_value(value, fallback)
        value = value.to_i
        value.positive? ? value : fallback
      end
  end
end

Folio::Ai.reset_configuration!

require_relative "ai/icons"
require_relative "ai/railtie"
