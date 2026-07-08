# frozen_string_literal: true

class Folio::Ai::Config
  attr_accessor :enabled,
                :default_provider,
                :model_fallback_enabled,
                :provider_request_storage,
                :max_prompt_chars,
                :rate_limit

  attr_writer :provider_model_options,
              :model_catalog_cache_ttl,
              :provider_request_timeout,
              :client_request_timeout_ms,
              :text_suggestions_queue

  def initialize(**attributes)
    default_attributes.merge(attributes).each do |key, value|
      public_send("#{key}=", value)
    end
  end

  def to_h
    {
      enabled:,
      default_provider:,
      provider_models:,
      provider_model_options: provider_model_options.deep_dup,
      model_catalog_cache_ttl:,
      model_fallback_enabled:,
      provider_request_storage:,
      provider_request_timeout:,
      client_request_timeout_ms:,
      max_prompt_chars:,
      rate_limit:,
      text_suggestions_queue:,
      current_form_snapshot_field_roots:,
      current_form_snapshot_file_placement_text_keys:,
    }
  end

  def provider_models=(value)
    @provider_models = (value || {}).to_h
  end

  def provider_models
    (@provider_models || {}).to_h.transform_keys(&:to_sym)
  end

  def provider_model_options
    @provider_model_options || {}
  end

  def current_form_snapshot_field_roots=(value)
    @current_form_snapshot_field_roots = normalize_config_key_list(value)
  end

  def current_form_snapshot_field_roots
    @current_form_snapshot_field_roots || Folio::Ai::DEFAULT_CURRENT_FORM_SNAPSHOT_FIELD_ROOTS
  end

  def current_form_snapshot_file_placement_text_keys=(value)
    @current_form_snapshot_file_placement_text_keys = normalize_config_key_list(value)
  end

  def current_form_snapshot_file_placement_text_keys
    @current_form_snapshot_file_placement_text_keys || Folio::Ai::DEFAULT_CURRENT_FORM_SNAPSHOT_FILE_PLACEMENT_TEXT_KEYS
  end

  def enabled?
    ActiveModel::Type::Boolean.new.cast(enabled) && !env_disabled?
  end

  def env_disabled?
    env_disabled_value.present?
  end

  def env_disabled_key
    "FOLIO_AI_DISABLED"
  end

  def env_disabled_value
    ENV[env_disabled_key]
  end

  def default_model(provider)
    provider_models.fetch(provider.to_sym)
  end

  def known_provider?(provider)
    return false if provider.blank?

    provider_models.key?(provider.to_sym)
  end

  def eligible_provider?(provider)
    return false unless known_provider?(provider)

    env_key = provider_api_key_env_key(provider)
    env_key.blank? || provider_api_key_env_value(provider).present?
  end

  def eligible_provider_models
    provider_models.select { |provider, _model| eligible_provider?(provider) }
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

  def text_suggestions_queue
    (@text_suggestions_queue.presence || :default).to_sym
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
    env_key = provider_api_key_env_key(provider)
    if env_key.blank?
      return nil if known_provider?(provider)

      raise Folio::Ai::UnknownProviderError, "Unknown AI provider: #{provider}"
    end

    provider_api_key_env_value(provider).presence ||
      raise(ArgumentError, "#{env_key} is not configured")
  end

  def provider_api_key_env_keys
    Folio::Ai::PROVIDER_API_KEY_ENV_KEYS
  end

  def provider_api_key_env_key(provider)
    return if provider.blank?

    provider_api_key_env_keys[provider.to_sym]
  end

  def provider_api_key_env_values
    provider_api_key_env_keys.transform_values { |env_key| ENV[env_key] }
  end

  def provider_api_key_env_value(provider)
    return if provider.blank?

    values = provider_api_key_env_values
    values[provider.to_sym] || values[provider.to_s]
  end

  def provider_models_env_key(provider)
    "FOLIO_AI_#{provider.to_s.upcase.gsub(/[^A-Z0-9]+/, '_')}_MODELS"
  end

  def provider_models_env_values
    provider_models.keys.index_with do |provider|
      ENV[provider_models_env_key(provider)]
    end
  end

  def provider_models_env_value(provider)
    return if provider.blank?

    values = provider_models_env_values
    values[provider.to_sym] || values[provider.to_s]
  end

  private
    def default_attributes
      {
        enabled: true,
        default_provider: :openai,
        provider_models: Folio::Ai::DEFAULT_PROVIDER_MODELS,
        provider_model_options: Folio::Ai::DEFAULT_PROVIDER_MODEL_OPTIONS.deep_dup,
        model_catalog_cache_ttl: 1.hour,
        model_fallback_enabled: true,
        provider_request_storage: false,
        provider_request_timeout: 30,
        client_request_timeout_ms: 45_000,
        max_prompt_chars: 80_000,
        rate_limit: nil,
        text_suggestions_queue: :default,
        current_form_snapshot_field_roots: Folio::Ai::DEFAULT_CURRENT_FORM_SNAPSHOT_FIELD_ROOTS,
        current_form_snapshot_file_placement_text_keys: Folio::Ai::DEFAULT_CURRENT_FORM_SNAPSHOT_FILE_PLACEMENT_TEXT_KEYS,
      }
    end

    def positive_config_value(value, fallback)
      value = value.to_i
      value.positive? ? value : fallback
    end

    def normalize_config_key_list(value)
      Array(value).filter_map { |item| item.to_s.strip.presence }.uniq
    end
end
