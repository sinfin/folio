# frozen_string_literal: true

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

  before_validation :normalize_keys

  scope :by_site, -> (site) { where(site:) }
  scope :by_user, -> (user) { where(user:) }
  scope :by_field, -> (integration_key, field_key) {
    where(integration_key: normalize_key(integration_key),
          field_key: normalize_key(field_key))
  }

  def self.find_or_initialize_for(user:, site:, integration_key:, field_key:)
    find_or_initialize_by(user:,
                          site:,
                          integration_key: normalize_key(integration_key),
                          field_key: normalize_key(field_key))
  end

  def self.upsert_instruction!(user:, site:, integration_key:, field_key:, instruction:)
    record = find_or_initialize_for(user:, site:, integration_key:, field_key:)
    record.instruction = instruction.to_s
    record.save!
    record
  end

  def self.normalize_key(key)
    key.to_s.strip
  end

  private
    def normalize_keys
      self.integration_key = self.class.normalize_key(integration_key)
      self.field_key = self.class.normalize_key(field_key)
      self.instruction = instruction.to_s
    end
end
