# frozen_string_literal: true

class Folio::UrlRedirect < Folio::ApplicationRecord
  include Folio::BelongsToSite
  include Folio::Publishable::Basic

  STATUS_CODES = {
    300 => "Multiple Choices",
    301 => "Moved Permanently",
    302 => "Found",
    303 => "See Other",
    304 => "Not Modified",
    305 => "Use Proxy",
    306 => "Switch Proxy",
    307 => "Temporary Redirect",
  }

  CACHE_KEY = "folio_url_redirects"
  CACHE_KEY_EXPIRES_IN = 1.day

  validates :url_from,
            :url_to,
            presence: true

  validates :url_from,
            presence: true,
            format: { with: /\A\// }

  validates :url_to,
            presence: true,
            format: { with: /\A(\/|https?:\/\/)/ }

  validates :url_to,
            :url_from,
            uniqueness: { scope: :site_id },
            if: -> { Rails.application.config.folio_url_redirects_per_site }

  validates :url_to,
            :url_from,
            uniqueness: true,
            if: -> { !Rails.application.config.folio_url_redirects_per_site }

  validates :match_query,
            :pass_query,
            inclusion: { in: [true, false] }

  validates :status_code,
            inclusion: { in: STATUS_CODES.keys },
            presence: true

  validate :validate_url_loop

  after_commit :refresh_url_redirects_cache

  def to_redirect_hash
    { url_to:, match_query:, pass_query:, status_code: }
  end

  def self.use_preview_tokens?
    false
  end

  def self.redirect_hash
    if Rails.application.config.folio_url_redirects_enabled
      hash = {}

      if Rails.application.config.folio_url_redirects_per_site
        self.published.includes(:site).each do |url_redirect|
          hash[url_redirect.site.env_aware_domain] ||= {}
          hash[url_redirect.site.env_aware_domain][url_redirect.url_from] = url_redirect.to_redirect_hash
        end

        hash.presence
      else
        hash["*"] ||= {}

        self.published.includes(:site).each do |url_redirect|
          hash["*"][url_redirect.url_from] ||= {}
          hash["*"][url_redirect.url_from] = url_redirect.to_redirect_hash
        end

        hash if hash["*"].present?
      end
    else
      {}
    end
  end

  def self.cache_aware_redirect_hash
    if Rails.application.config.action_controller.perform_caching
      Rails.cache.fetch(CACHE_KEY, expires_in: CACHE_KEY_EXPIRES_IN) do
        redirect_hash
      end
    else
      redirect_hash
    end
  end

  def self.handle_env(env)
    if Rails.application.config.folio_url_redirects_enabled
      hash = cache_aware_redirect_hash

      if hash.present?
        value = if Rails.application.config.folio_url_redirects_per_site
          env_host = env["HTTP_HOST"] || env["SERVER_NAME"]
          hash[env_host]
        else
          hash["*"]
        end

        if value.present?
          env_path = env["PATH_INFO"]
          env_query = env["QUERY_STRING"]

          target = nil

          if env_query.blank?
            target = value[env_path]
          else
            env_path_with_query = env_query.present? ? "#{env_path}?#{env_query}" : env_path

            target = value[env_path_with_query]

            if target.nil?
              target = value[env_path]

              if target && target[:match_query]
                target = nil
              end
            end
          end

          if target
            url = if env_query.present? && target[:pass_query]
              "#{target[:url_to]}#{target[:url_to].include?("?") ? "&" : "?"}#{env_query}"
            else
              target[:url_to]
            end

            [target[:status_code], { "Location" => url }, []]
          end
        end
      end
    end
  end

  private
    def validate_url_loop
      return if url_from.blank?
      return if url_to.blank?
      return if site_id.blank?

      if url_from == url_to
        errors.add(:url_to, :same_as_url_from, attribute_name: self.class.human_attribute_name(:url_from))
      end

      base_scope = self.class
      base_scope = base_scope.by_site(site) if Rails.application.config.folio_url_redirects_per_site

      record = base_scope.where(url_to: url_from).or(base_scope.where(url_from: url_to)).first

      return if record.nil?

      if record.url_from == url_to
        errors.add(:url_to,
                   :same_as_another_url_from,
                   attribute_name: self.class.human_attribute_name(:url_from),
                   model_name: self.class.model_name.human.downcase)
      else
        errors.add(:url_from,
                   :same_as_another_url_to,
                   attribute_name: self.class.human_attribute_name(:url_to),
                   model_name: self.class.model_name.human.downcase)
      end
    end

    def refresh_url_redirects_cache
      Rails.cache.delete(CACHE_KEY)
      self.class.cache_aware_redirect_hash
    end
end

# == Schema Information
#
# Table name: folio_url_redirects
#
#  id          :bigint(8)        not null, primary key
#  title       :string
#  url_from    :string
#  url_to      :string
#  status_code :integer          default(301)
#  published   :boolean          default(TRUE)
#  match_query :boolean          default(FALSE)
#  pass_query  :boolean          default(TRUE)
#  site_id     :bigint(8)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_folio_url_redirects_on_site_id  (site_id)
#
