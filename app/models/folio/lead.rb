# frozen_string_literal: true

class Folio::Lead < Folio::ApplicationRecord
  include AASM

  attr_accessor :verified_captcha

  belongs_to :visit, optional: true

  # Validations
  validates_format_of :email, with: Folio::EMAIL_REGEXP,
                              unless: :skip_email_validation?
  validates :note,
            presence: true,
            unless: :skip_note_validation?

  validate :validate_verified_captcha

  # Scopes
  scope :not_handled, -> { submitted }
  scope :ordered, -> { order(created_at: :desc) }

  pg_search_scope :by_query,
                  against: %i[email name phone],
                  ignoring: :accents

  aasm do
    state :submitted, initial: true
    state :handled

    event :handle do
      transitions from: :submitted, to: :handled
    end

    event :unhandle do
      transitions from: :handled, to: :submitted
    end
  end

  def title
    email.presence || phone.presence || self.class.model_name.human
  end

  def self.csv_attribute_names
    %i[id email phone note created_at name url state]
  end

  def self.clears_page_cache_on_save?
    false
  end

  def csv_attributes
    self.class.csv_attribute_names.map do |attr|
      case attr
      when :state
        human_state_name
      else
        send(attr)
      end
    end
  end

  def skip_email_validation?
    false
  end

  private

    def skip_note_validation?
      false
    end

    def validate_verified_captcha
      return if verified_captcha == true
      return if verified_captcha.nil?
      errors.add(:verified_captcha, :invalid)
    end
end

# == Schema Information
#
# Table name: folio_leads
#
#  id              :bigint(8)        not null, primary key
#  email           :string
#  phone           :string
#  note            :text
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  name            :string
#  url             :string
#  additional_data :json
#  aasm_state      :string           default("submitted")
#  visit_id        :bigint(8)
#
# Indexes
#
#  index_folio_leads_on_visit_id  (visit_id)
#
