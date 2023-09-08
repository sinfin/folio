# frozen_string_literal: true

class Folio::Lead < Folio::ApplicationRecord
  include AASM
  include Folio::BelongsToSite
  include PgSearch::Model

  has_sanitized_fields :email, :phone, :note, :name

  attr_accessor :verified_captcha

  # Validations
  validates_format_of :email, with: Folio::EMAIL_REGEXP,
                              unless: :skip_email_validation?
  validates :note,
            presence: true,
            unless: :skip_note_validation?

  validate :validate_verified_captcha

  # Scopes
  scope :not_handled, -> { submitted }
  scope :ordered, -> { order(id: :desc) }
  scope :by_state, -> (state) { where(aasm_state: state) }

  pg_search_scope :by_query,
                  against: %i[email name phone],
                  ignoring: :accents,
                  using: {
                    tsearch: { prefix: true }
                  }

  aasm do
    state :submitted, initial: true, color: "red"
    state :pending, color: "orange"
    state :handled, color: "green"

    event :to_submitted do
      transitions from: %i[pending handled], to: :submitted
    end

    event :to_pending do
      transitions from: %i[submitted handled], to: :pending
    end

    event :to_handled do
      transitions from: %i[submitted pending], to: :handled
    end
  end

  def title
    email.presence || phone.presence || self.class.model_name.human
  end

  alias_method :to_label, :title

  def self.csv_attribute_names
    %i[id email phone note created_at name url aasm_state]
  end

  def self.clears_page_cache_on_save?
    false
  end

  def self.console_sidebar_count
    by_state("submitted").count
  end

  def csv_attributes(controller = nil)
    self.class.csv_attribute_names.map do |attr|
      case attr
      when :aasm_state
        aasm.human_state
      else
        send(attr)
      end
    end
  end

  def skip_email_validation?
    false
  end

  def send_notification_mail?
    true
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
#  site_id         :bigint(8)
#
# Indexes
#
#  index_folio_leads_on_site_id  (site_id)
#
