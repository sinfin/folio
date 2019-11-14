# frozen_string_literal: true

class Folio::Site < Folio::ApplicationRecord
  include Folio::Singleton

  after_commit :clear_fragment_cache!

  # Validations
  validates :title, :email, :locale, :locales,
            presence: true

  validates :domain,
            uniqueness: true

  validates_format_of :email,
                      :email_from,
                      with: Folio::EMAIL_REGEXP,
                      allow_nil: true

  validate :system_emails_should_be_valid

  def self.additional_params
    []
  end

  def self.social_link_sites
    # class method is better than a constant as one might want to override it
    %i[facebook
       instagram
       twitter
       linkedin
       youtube
       appstore
       google_play
       pinterest
       messenger]
  end

  %i[system_email system_email_copy].each do |attr|
    define_method("#{attr}_array") do
      return [] if send(attr).nil?

      send(attr).gsub(' ', '').split(',')
    end
  end

  private

    def clear_fragment_cache!
      Rails.cache.clear
    end

    def system_emails_should_be_valid
      %i[system_email system_email_copy].each do |attr|
        send(:"#{attr}_array").each do |email|
          unless Folio::EMAIL_REGEXP.match?(email)
            errors.add(attr, :invalid)
            break
          end
        end
      end
    end
end

# == Schema Information
#
# Table name: folio_sites
#
#  id                             :bigint(8)        not null, primary key
#  title                          :string
#  domain                         :string
#  email                          :string
#  phone                          :string
#  locale                         :string
#  locales                        :string           default([]), is an Array
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#  google_analytics_tracking_code :string
#  facebook_pixel_code            :string
#  social_links                   :json
#  address                        :text
#  description                    :text
#  turbo_mode                     :boolean          default(FALSE)
#  system_email                   :string
#  system_email_copy              :string
#  email_from                     :string
#
# Indexes
#
#  index_folio_sites_on_domain  (domain)
#
