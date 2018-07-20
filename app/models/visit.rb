# frozen_string_literal: true

class Visit < Folio::ApplicationRecord
  # Relations
  has_many :ahoy_events, class_name: 'Ahoy::Event'
  belongs_to :site, class_name: 'Folio::Site'
  belongs_to :account, class_name: 'Folio::Account', optional: true

  # Scopes
  default_scope -> { order(started_at: :desc) }

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

# == Schema Information
#
# Table name: visits
#
#  id               :bigint(8)        not null, primary key
#  visit_token      :string
#  visitor_token    :string
#  ip               :string
#  user_agent       :text
#  referrer         :text
#  landing_page     :text
#  site_id          :bigint(8)
#  account_id       :bigint(8)
#  referring_domain :string
#  search_keyword   :string
#  browser          :string
#  os               :string
#  device_type      :string
#  screen_height    :integer
#  screen_width     :integer
#  country          :string
#  region           :string
#  city             :string
#  postal_code      :string
#  latitude         :decimal(, )
#  longitude        :decimal(, )
#  utm_source       :string
#  utm_medium       :string
#  utm_term         :string
#  utm_content      :string
#  utm_campaign     :string
#  started_at       :datetime
#
# Indexes
#
#  index_visits_on_account_id   (account_id)
#  index_visits_on_site_id      (site_id)
#  index_visits_on_visit_token  (visit_token) UNIQUE
#
