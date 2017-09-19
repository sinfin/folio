# frozen_string_literal: true

require 'test_helper'

module Folio
  class SiteTest < ActiveSupport::TestCase
    # test "the truth" do
    #   assert true
    # end
  end
end

# == Schema Information
#
# Table name: folio_sites
#
#  id                             :integer          not null, primary key
#  title                          :string
#  domain                         :string
#  locale                         :string           default("en")
#  locales                        :string           default([]), is an Array
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#  google_analytics_tracking_code :string
#  facebook_pixel_code            :string
#
# Indexes
#
#  index_folio_sites_on_domain  (domain)
#
