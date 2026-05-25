# frozen_string_literal: true

module Folio::Ai::SiteConcern
  extend ActiveSupport::Concern

  included do
    attribute :ai_settings, default: -> { {} }

    has_many :ai_user_instructions,
             class_name: "Folio::Ai::UserInstruction",
             foreign_key: :site_id,
             inverse_of: :site,
             dependent: :destroy

    validate :ai_settings_should_be_valid, if: -> { Folio::Ai.enabled? }
    before_validation :set_default_ai_settings
  end

  def ai_settings_data
    (self[:ai_settings].presence || {}).deep_stringify_keys
  end

  def ai_enabled?
    ActiveModel::Type::Boolean.new.cast(ai_settings_data["enabled"])
  end

  def ai_field_settings(integration_key:, field_key:)
    ai_settings_data.dig("integrations",
                         integration_key.to_s,
                         "fields",
                         field_key.to_s) || {}
  end

  def ai_prompt_for(integration_key:, field_key:)
    ai_field_settings(integration_key:, field_key:)["prompt"].to_s.strip.presence
  end

  def ai_field_enabled_for?(integration_key:, field_key:)
    settings = ai_field_settings(integration_key:, field_key:)

    return true unless settings.key?("enabled")

    ActiveModel::Type::Boolean.new.cast(settings["enabled"])
  end

  def ai_prompt_enabled_for?(integration_key:, field_key:)
    ai_enabled? &&
      ai_field_enabled_for?(integration_key:, field_key:) &&
      ai_prompt_for(integration_key:, field_key:).present?
  end

  def set_ai_prompt(integration_key:, field_key:, prompt:)
    data = ai_settings_data.deep_dup
    data["integrations"] ||= {}
    data["integrations"][integration_key.to_s] ||= {}
    data["integrations"][integration_key.to_s]["fields"] ||= {}
    data["integrations"][integration_key.to_s]["fields"][field_key.to_s] ||= {}
    data["integrations"][integration_key.to_s]["fields"][field_key.to_s]["prompt"] = prompt.to_s
    self.ai_settings = data
  end

  private
    def ai_settings_should_be_valid
      return if self[:ai_settings].blank?

      unless self[:ai_settings].is_a?(Hash)
        errors.add(:ai_settings, :invalid_ai_settings_structure)
        return
      end

      validate_ai_provider(ai_settings_data["default_provider"])
      validate_ai_integrations(ai_settings_data["integrations"])
    end

    def validate_ai_integrations(integrations)
      return if integrations.blank?
      return add_invalid_ai_settings_structure unless integrations.is_a?(Hash)

      integrations.each do |key, settings|
        validate_ai_integration(key, settings || {})
      end
    end

    def validate_ai_integration(key, settings)
      integration = Folio::Ai.registry.integration(key)
      return errors.add(:ai_settings, :unknown_ai_integration, key:) if integration.blank?
      return if settings.blank?
      return add_invalid_ai_settings_structure unless settings.is_a?(Hash)

      validate_ai_provider(settings["default_provider"])
      validate_ai_fields(integration, settings["fields"])
    end

    def validate_ai_fields(integration, fields)
      return if fields.blank?
      return add_invalid_ai_settings_structure unless fields.is_a?(Hash)

      fields.each do |key, settings|
        validate_ai_field(integration, key, settings || {})
      end
    end

    def validate_ai_field(integration, key, settings)
      field = Folio::Ai.registry.field(integration.key, key)
      return errors.add(:ai_settings, :unknown_ai_field, key:, integration: integration.key) if field.blank?
      return if settings.blank?
      return add_invalid_ai_settings_structure unless settings.is_a?(Hash)

      validate_ai_provider(settings["provider"])
    end

    def validate_ai_provider(provider)
      return if provider.blank?
      return if Folio::Ai.known_provider?(provider)

      errors.add(:ai_settings, :unknown_ai_provider, provider:)
    end

    def add_invalid_ai_settings_structure
      errors.add(:ai_settings, :invalid_ai_settings_structure)
    end

    def set_default_ai_settings
      self.ai_settings = {} if self[:ai_settings].nil?
    end
end
