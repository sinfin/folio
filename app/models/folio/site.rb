# frozen_string_literal: true

module Folio
  class Site < ApplicationRecord
    # Relations
    has_many :nodes, class_name: 'Folio::Node'
    has_many :visits

    # Validations
    validates :title, presence: true
    validates :domain, uniqueness: true

    def url
      "#{scheme}://#{self.domain}"
    end

    def self.additional_params
      []
    end

    def self.current
      self.first
    end

    private

      def scheme
        'http'
      end
  end
end

# == Schema Information
#
# Table name: folio_sites
#
#  id                             :integer          not null, primary key
#  title                          :string
#  domain                         :string
#  email                          :string
#  phone                          :string
#  locale                         :string           default("en")
#  locales                        :string           default([]), is an Array
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#  google_analytics_tracking_code :string
#  facebook_pixel_code            :string
#  social_links                   :json
#  address                        :text
#  description                    :text
#
# Indexes
#
#  index_folio_sites_on_domain  (domain)
#
