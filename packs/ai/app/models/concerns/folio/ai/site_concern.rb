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

    before_validation :set_default_ai_settings
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
    ai_settings_data["model"].presence || Folio::Ai.config.default_model(ai_provider)
  end

  def ai_prompt_for(record_key:, field_key:)
    ai_settings_data.dig("integrations",
                         record_key.to_s,
                         "fields",
                         field_key.to_s,
                         "prompt").to_s.strip.presence
  end

  private
    def set_default_ai_settings
      self.ai_settings = {} if ai_settings.nil?
    end
end
