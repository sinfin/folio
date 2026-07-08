# frozen_string_literal: true

# Stores AI pack runtime configuration, including provider defaults, job queue,
# and request timeout settings.
class Folio::Ai::Config
  attr_accessor :enabled,
                :default_provider

  attr_writer :client_request_timeout_ms,
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
      text_suggestions_queue:,
      client_request_timeout_ms:,
    }
  end

  def enabled?
    ActiveModel::Type::Boolean.new.cast(enabled)
  end

  def provider_models
    (@provider_models || {}).to_h.transform_keys(&:to_sym)
  end

  def provider_models=(value)
    @provider_models = (value || {}).to_h
  end

  def default_model(provider = default_provider)
    provider_models.fetch(provider.to_sym)
  end

  def known_provider?(provider)
    provider.present? && provider_models.key?(provider.to_sym)
  end

  def text_suggestions_queue
    (@text_suggestions_queue.presence || :default).to_sym
  end

  def client_request_timeout_ms
    value = @client_request_timeout_ms.to_i
    value.positive? ? value : 45_000
  end

  private
    def default_attributes
      {
        enabled: !Folio::Ai.disabled_by_env?,
        default_provider: :openai,
        provider_models: { openai: Folio::Ai::DEFAULT_OPENAI_MODEL },
        text_suggestions_queue: :default,
        client_request_timeout_ms: 45_000,
      }
    end
end
