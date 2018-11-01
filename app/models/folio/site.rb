# frozen_string_literal: true

module Folio
  class Site < ApplicationRecord
    include ::Folio::Singleton

    after_commit :clear_fragment_cache!

    # Validations
    validates :title, :locale, :locales,
              presence: true

    validates :domain,
              uniqueness: true

    validates_format_of :email,
                        with: ::Folio::EMAIL_REGEXP

    def self.additional_params
      []
    end

    def self.social_link_sites
      # class method is better than a constant as one might want to override it
      %i[facebook
         instagram
         twitter
         youtube
         appstore
         google_play
         pinterest
         messenger]
    end

    private

      def clear_fragment_cache!
        Rails.cache.clear
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
#
# Indexes
#
#  index_folio_sites_on_domain  (domain)
#
