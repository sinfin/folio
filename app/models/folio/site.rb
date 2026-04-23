# frozen_string_literal: true

class Folio::Site < Folio::ApplicationRecord
  include Folio::FriendlyId
  include Folio::HasAttachments
  include Folio::HasHeaderMessage
  include Folio::Positionable
  include Folio::StiPreload

  attribute :ai_settings, default: -> { {} }

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

  has_many :source_users, class_name: "Folio::User",
                          foreign_key: :source_site_id,
                          inverse_of: :source_site,
                          dependent: :nullify
  has_many :auth_users, class_name: "Folio::User",
                        foreign_key: :auth_site_id,
                        inverse_of: :auth_site,
                        dependent: :destroy

  has_many :site_user_links, class_name: "Folio::SiteUserLink",
                             foreign_key: :site_id,
                             inverse_of: :site,
                             dependent: :destroy
  has_many :users, through: :site_user_links,
                          source: :user

  has_many :ai_user_instructions,
           class_name: "Folio::Ai::UserInstruction",
           foreign_key: :site_id,
           inverse_of: :site,
           dependent: :destroy

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

  before_validation :set_default_ai_settings

  after_commit :nillify_folio_current_site_records

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
       linktree
       appstore
       google_play
       messenger]
  end

  %i[system_email system_email_copy].each do |attr|
    define_method("#{attr}_array") do
      return [] if send(attr).nil?

      send(attr).delete(" ").split(",")
    end
  end

  def env_aware_root_url
    scheme = if Folio::Current.url.present?
      uri = URI.parse(Folio::Current.url)
      uri.scheme
    elsif (Rails.env.test? || Rails.env.development?) && ENV["FORCE_SSL"] != "1"
      "http"
    else
      "https"
    end

    "#{scheme}://#{env_aware_domain}/"
  end

  def env_aware_domain
    if Rails.env.development? || ENV["DEV_TESTING_PRODUCTION"]
      port = if Folio::Current.url.present?
        uri = URI.parse(Folio::Current.url)
        uri.port
      end

      "#{slug}.localhost:#{port || "3000"}"
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

  def layout_assets_javascripts_path
    layout_assets_path
  end

  def layout_assets_stylesheets_path
    layout_assets_path
  end

  def layout_favicon_path
    "/"
  end

  def layout_console_favicon_path
    layout_favicon_path
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

  def console_locale
    locale
  end

  def locales_as_sym
    locales.map(&:to_sym)
  end

  def og_image_with_fallback
    Rails.cache.fetch(["site#og_image_with_fallback", id, updated_at, ENV["CURRENT_RELEASE_COMMIT_HASH"]]) do
      if og_image
        og_image.thumb(Folio::OG_IMAGE_DIMENSIONS).url
      else
        og_image_fallback
      end
    end
  end

  def og_image_fallback
    "/fb-share.png"
  end

  def console_dashboard_redirect_path_name
    Rails.application.config.folio_console_report_redirect
  end

  def copyright_info
    if copyright_info_source
      copyright_info_source.gsub("{YEAR}", Time.current.year.to_s)
    end
  end

  def folio_console_sidebar_title_image_path
    ::Rails.application.config.folio_console_sidebar_title_image_path
  end

  def available_user_roles_ary
    available_user_roles.presence || []
  end

  def site # for Ability checks
    self
  end

  def mailer_logo_data
    {
      png_src: "https://sinfin-folio.s3.eu-central-1.amazonaws.com/mailer/logos/folio_logo.png",
      light_png_src: "https://sinfin-folio.s3.eu-central-1.amazonaws.com/mailer/logos/folio_logo_light.png",
      width: 119,
      height: 60,
    }
  end

  def attribute_types_classes
    Folio::AttributeType.descendants
  end

  def structured_data_config
    {}
  end

  def ai_settings_data
    (self[:ai_settings].presence || {}).deep_stringify_keys
  end

  def ai_enabled?
    ActiveModel::Type::Boolean.new.cast(ai_settings_data["enabled"])
  end

  def ai_field_settings(integration_key:, field_key:)
    ai_settings_data.dig("integrations",
                         integration_key.to_s,
                         "fields",
                         field_key.to_s) || {}
  end

  def ai_prompt_for(integration_key:, field_key:)
    ai_field_settings(integration_key:, field_key:)["prompt"].to_s.strip.presence
  end

  def ai_prompt_enabled_for?(integration_key:, field_key:)
    ai_enabled? && ai_prompt_for(integration_key:, field_key:).present?
  end

  def set_ai_prompt(integration_key:, field_key:, prompt:)
    data = ai_settings_data.deep_dup
    data["integrations"] ||= {}
    data["integrations"][integration_key.to_s] ||= {}
    data["integrations"][integration_key.to_s]["fields"] ||= {}
    data["integrations"][integration_key.to_s]["fields"][field_key.to_s] ||= {}
    data["integrations"][integration_key.to_s]["fields"][field_key.to_s]["prompt"] = prompt.to_s
    self.ai_settings = data
  end

  def folio_html_sanitization_config
    {
      enabled: true,
      attributes: {
        header_message: :rich_text,
      }
    }
  end

  def self.sti_paths
    [
      Folio::Engine.root.join("app/models/folio/site"),
      Rails.root.join("app/models/**/site"),
    ]
  end

  # Subtitle settings
  def subtitle_languages
    self[:subtitle_languages].presence || Rails.application.config.folio_files_video_enabled_subtitle_languages
  end

  # Virtual attribute for comma-separated form input
  def subtitle_languages_string
    subtitle_languages.join(", ")
  end

  def subtitle_languages_string=(value)
    if value.present?
      self.subtitle_languages = value.split(",").map(&:strip).reject(&:blank?)
    else
      self.subtitle_languages = []
    end
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

    def nillify_folio_current_site_records
      Folio::Current.nillify_site_records
    end

    def set_default_ai_settings
      self.ai_settings = {} if self[:ai_settings].nil?
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
#  phone_secondary                   :string
#  address_secondary                 :text
#  subtitle_languages                :jsonb
#  subtitle_auto_generation_enabled  :boolean          default(FALSE)
#  ai_settings                       :jsonb            not null
#
# Indexes
#
#  index_folio_sites_on_domain              (domain)
#  index_folio_sites_on_position            (position)
#  index_folio_sites_on_slug                (slug)
#  index_folio_sites_on_subtitle_languages  (subtitle_languages) USING gin
#  index_folio_sites_on_type                (type)
#  index_folio_sites_on_ai_settings         (ai_settings) USING gin
#
