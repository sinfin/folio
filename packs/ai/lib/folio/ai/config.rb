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
      text_suggestions_queue:,
      client_request_timeout_ms:,
    }
  end

  def enabled?
    ActiveModel::Type::Boolean.new.cast(enabled)
  end

  def default_model(provider = default_provider)
    Folio::Ai.provider_class(provider).default_model
  end

  def known_provider?(provider)
    return false if provider.blank?

    Folio::Ai.provider_class(provider)
    true
  rescue ArgumentError
    false
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
        text_suggestions_queue: :default,
        client_request_timeout_ms: 45_000,
      }
    end
end
