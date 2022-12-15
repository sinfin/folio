# frozen_string_literal: true

class Folio::Site < Folio::ApplicationRecord
  include Folio::FriendlyId
  include Folio::HasHeaderMessage
  include Folio::Positionable

  if Rails.application.config.folio_site_is_a_singleton
    include Folio::Singleton
  else
    # use specific STI types if site is not a singleton
    validates :type,
              presence: true

    [
      [:email_templates, "Folio::EmailTemplate"],
      [:leads, "Folio::Lead"],
      [:menus, "Folio::Menu"],
      [:newsletter_subscriptions, "Folio::NewsletterSubscription"],
      [:pages, "Folio::Page"],
    ].each do |key, class_name|
      has_many key, class_name:,
                    foreign_key: :site_id,
                    dependent: :nullify
    end
  end

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
       tiktok
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

      send(attr).delete(" ").split(",")
    end
  end

  def env_aware_root_url
    "http://#{env_aware_domain}/"
  end

  def env_aware_domain
    if Rails.env.development?
      "dev-#{domain}:3000"
    else
      domain
    end
  end

  def pretty_domain
    if domain.present?
      domain.delete_prefix("www.")
    end
  end

  def layout_name
    "folio/application"
  end

  def layout_assets_path
    "application"
  end

  def i18n_key_base
    @i18n_key_base ||= self.class.to_s.deconstantize.underscore
  end

  def layout_twitter_meta
    {
      "twitter:card" => "summary",
    }
  end

  def <=>(other)
    res = self.title <=> other.title
    return res unless res.zero?

    self.id <=> other.id
  end

  def console_form_tabs_base
    %i[
      header_message
      contacts
      analytics
      site_social_links
      settings
    ]
  end

  def console_form_tabs
    console_form_tabs_base
  end

  def og_image_fallback
    "/fb-share.png"
  end

  def console_dashboard_redirect_path_name
    Rails.application.config.folio_console_dashboard_redirect
  end

  private
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
#
# Indexes
#
#  index_folio_sites_on_domain    (domain)
#  index_folio_sites_on_position  (position)
#  index_folio_sites_on_slug      (slug)
#  index_folio_sites_on_type      (type)
#
