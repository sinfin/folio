# frozen_string_literal: true

module Folio::Ai
  DEFAULT_OPENAI_MODEL = "gpt-5.4-mini"
  PREMIUM_OPENAI_MODEL = "gpt-5.5"
  DEFAULT_ANTHROPIC_MODEL = "claude-opus-4-7"
  DEFAULT_PROVIDER_MODELS = {
    openai: DEFAULT_OPENAI_MODEL,
    anthropic: DEFAULT_ANTHROPIC_MODEL,
  }.freeze
  DEFAULT_PROVIDER_MODEL_OPTIONS = {
    openai: {
      DEFAULT_OPENAI_MODEL => { label: "GPT-5.4 mini" }.freeze,
      PREMIUM_OPENAI_MODEL => { label: "GPT-5.5", cost_tier: "premium" }.freeze,
    }.freeze,
  }.freeze
  PROVIDER_API_KEY_ENV_KEYS = {
    openai: "FOLIO_AI_OPENAI_API_KEY",
    anthropic: "FOLIO_AI_ANTHROPIC_API_KEY",
  }.freeze
  PACK_ASSETS = {
    javascripts: %w[folio_pack_ai],
    stylesheets: %w[folio_pack_ai],
  }.freeze
  DEFAULT_CURRENT_FORM_SNAPSHOT_FIELD_ROOTS = %w[
    title
    perex
    description
    meta_title
    meta_description
    og_title
    og_description
    content
    body
  ].freeze
  DEFAULT_CURRENT_FORM_SNAPSHOT_FILE_PLACEMENT_TEXT_KEYS = %w[
    title
    alt
    description
    folio_embed_data
  ].freeze

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
    def config
      @config ||= Folio::Ai::Config.new
    end

    def configure
      yield config
    end

    def reset_configuration!
      @config = Folio::Ai::Config.new
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

require_relative "ai/config"

Folio::Ai.reset_configuration!

require_relative "ai/railtie"
