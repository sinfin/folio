# frozen_string_literal: true

# Persists per-user prompt instructions for one registered record field.
class Folio::Ai::UserInstruction < Folio::ApplicationRecord
  self.table_name = "folio_ai_user_instructions"

  belongs_to :user,
             class_name: "Folio::User",
             inverse_of: :ai_user_instructions
  belongs_to :site,
             class_name: "Folio::Site",
             inverse_of: :ai_user_instructions

  validates :integration_key,
            :field_key,
            presence: true
  validates :instruction,
            length: { maximum: 10_000 }

  before_validation :normalize_values

  def self.find_or_initialize_for(user:, site:, record_key:, field_key:)
    find_or_initialize_by(user:,
                          site:,
                          integration_key: normalize_key(record_key),
                          field_key: normalize_key(field_key))
  end

  def self.upsert_instruction!(user:, site:, record_key:, field_key:, instruction:)
    find_or_initialize_for(user:, site:, record_key:, field_key:).tap do |record|
      record.instruction = instruction.to_s
      record.save!
    end
  end

  def self.normalize_key(key)
    key.to_s.strip
  end

  private
    def normalize_values
      self.integration_key = self.class.normalize_key(integration_key)
      self.field_key = self.class.normalize_key(field_key)
      self.instruction = instruction.to_s
    end
end
