# frozen_string_literal: true

# Adds AI settings, provider/model lookup, prompt availability, and instruction
# associations to Folio sites.
module Folio::Ai::SiteConcern
  extend ActiveSupport::Concern

  included do
    attribute :ai_settings, default: -> { {} }

    has_many :ai_user_instructions,
             class_name: "Folio::Ai::UserInstruction",
             foreign_key: :site_id,
             inverse_of: :site,
             dependent: :destroy

    before_validation :set_default_ai_settings
    before_validation :normalize_ai_model
  end

  def ai_settings_data
    (self[:ai_settings].presence || {}).deep_stringify_keys
  end

  def ai_enabled?
    ActiveModel::Type::Boolean.new.cast(ai_settings_data["enabled"])
  end

  def ai_provider
    ai_settings_data["provider"].presence || Folio::Ai.config.default_provider.to_s
  end

  def ai_model
    provider_class = ai_provider_class(ai_provider)
    model = ai_settings_data["model"].presence
    return model if provider_class.nil? || explicit_provider_model_available?(provider_class, model)

    provider_class.default_model
  end

  def ai_settings_for(record_key:, key:, grouped: false)
    collection_key = grouped ? "groups" : "fields"

    ai_settings_data.dig("integrations",
                         record_key.to_s,
                         collection_key,
                         key.to_s) || {}
  end

  def ai_prompt_for(record_key:, key:, grouped: false)
    ai_settings_for(record_key:,
                    key:,
                    grouped:).dig("prompt").to_s.strip.presence
  end

  def ai_enabled_for?(record_key:, key:, grouped: false)
    settings = ai_settings_for(record_key:,
                               key:,
                               grouped:)
    return true unless settings.key?("enabled")

    ActiveModel::Type::Boolean.new.cast(settings["enabled"])
  end

  def ai_prompt_enabled_for?(record_key:, key:, grouped: false)
    ai_enabled? &&
      ai_enabled_for?(record_key:,
                      key:,
                      grouped:) &&
      ai_prompt_for(record_key:,
                    key:,
                    grouped:).present?
  end

  private
    def set_default_ai_settings
      self.ai_settings = {} if ai_settings.nil?
    end

    def normalize_ai_model
      settings = ai_settings_data
      provider = settings["provider"].presence
      return if provider.blank?

      provider_class = ai_provider_class(provider)
      return if provider_class.nil?

      model = settings["model"].presence
      return if model.blank? || explicit_provider_model_available?(provider_class, model)

      settings["model"] = ""
      self.ai_settings = settings
    end

    def ai_provider_class(provider)
      Folio::Ai.provider_class(provider)
    rescue ArgumentError
      nil
    end

    def explicit_provider_model_available?(provider_class, model)
      model.present? && explicit_provider_models(provider_class).include?(model.to_s)
    end

    def explicit_provider_models(provider_class)
      default_model = provider_class.default_model.to_s

      provider_class.models.map(&:to_s).reject { |model| model == default_model }
    end
end
