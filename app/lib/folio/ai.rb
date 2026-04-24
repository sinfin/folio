# frozen_string_literal: true

module Folio::Ai
  DEFAULT_OPENAI_MODEL = "gpt-5.5"
  DEFAULT_ANTHROPIC_MODEL = "claude-opus-4-7"

  Error = Class.new(StandardError)
  UnknownProviderError = Class.new(Error)
  ProviderError = Class.new(Error)
  ProviderTimeoutError = Class.new(ProviderError)
  ProviderRateLimitError = Class.new(ProviderError)
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
    suggestion_count
    latency_ms
    error_code
    record_class
  ].freeze

  class << self
    def registry
      @registry ||= Folio::Ai::Registry.new
    end

    def reset_registry!
      @registry = Folio::Ai::Registry.new
    end

    def register_integration(...)
      registry.register_integration(...)
    end

    def enabled?
      Rails.application.config.folio_ai_enabled && !env_disabled?
    end

    def env_disabled?
      ENV["FOLIO_AI_DISABLED"].present?
    end

    def default_model(provider)
      Rails.application.config.folio_ai_provider_models.fetch(provider.to_sym)
    end

    def provider_models
      Rails.application.config.folio_ai_provider_models
    end

    def known_provider?(provider)
      provider_models.key?(provider.to_sym)
    end

    def provider_adapter(provider:, model: default_model(provider), api_key: nil)
      provider_adapter_class(provider).new(api_key: api_key || provider_api_key(provider),
                                           model:)
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
        ENV.fetch("OPENAI_API_KEY")
      when :anthropic
        ENV.fetch("ANTHROPIC_API_KEY")
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
  end
end
