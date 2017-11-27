# frozen_string_literal: true

class Visit < Folio::ApplicationRecord
  # Relations
  has_many :ahoy_events, class_name: 'Ahoy::Event'
  belongs_to :site, class_name: 'Folio::Site'
  belongs_to :account, class_name: 'Folio::Account', optional: true

  # Scopes
  scope :with_account_id, -> (id) {
    where(account_id: id)
  }

  scope :by_query, -> (q) {
    if q.present?
      args = ["%#{q}%"] * 4
      where('referrer ILIKE ? OR landing_page ILIKE ? OR country ILIKE ? OR city ILIKE ?', *args)
    else
      where(nil)
    end
  }

  def landing_page_path
    begin
      URI.parse(landing_page).path
    rescue URI::InvalidURIError
      "[ERROR] #{landing_page}"
    end
  end

  def title
    "#{id}"
  end

  def to_label
    title
  end
end
