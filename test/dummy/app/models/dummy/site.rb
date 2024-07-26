# frozen_string_literal: true

class Dummy::Site < Folio::Site
  def self.console_sidebar_before_menu_links
    if defined?(Dummy::Blog)
      %w[
        Dummy::Blog::Article
        Dummy::Blog::Author
        Dummy::Blog::Topic
      ]
    end
  end
end

# == Schema Information
#
# Table name: folio_sites
#
#  id                                :bigint(8)        not null, primary key
#  title                             :string
#  domain                            :string
#  email                             :string
#  phone                             :string
#  locale                            :string
#  locales                           :string           default([]), is an Array
#  created_at                        :datetime         not null
#  updated_at                        :datetime         not null
#  google_analytics_tracking_code    :string
#  facebook_pixel_code               :string
#  social_links                      :json
#  address                           :text
#  description                       :text
#  system_email                      :string
#  system_email_copy                 :string
#  email_from                        :string
#  google_analytics_tracking_code_v4 :string
#  header_message                    :text
#  header_message_published          :boolean          default(FALSE)
#  header_message_published_from     :datetime
#  header_message_published_until    :datetime
#  type                              :string
#  slug                              :string
#  position                          :integer
#  copyright_info_source             :string
#  available_user_roles              :jsonb
#
# Indexes
#
#  index_folio_sites_on_domain    (domain)
#  index_folio_sites_on_position  (position)
#  index_folio_sites_on_slug      (slug)
#  index_folio_sites_on_type      (type)
#
