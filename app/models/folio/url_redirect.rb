# frozen_string_literal: true

class Folio::UrlRedirect < Folio::ApplicationRecord
  include Folio::BelongsToSite
  include Folio::Publishable::Basic

  STATUS_CODES = {
    301 => "Moved Permanently",
    302 => "Found",
    303 => "See Other",
    307 => "Temporary Redirect",
  }

  CACHE_KEY_BASE = "folio_url_redirects"
  CACHE_KEY_EXPIRES_IN = 1.day

  validates :url_from,
            :url_to,
            presence: true

  validates :title,
            presence: true,
            uniqueness: { scope: :site_id }

  validates :url_to,
            allow_nil: true,
            format: { with: /\A(\/|https?:\/\/)/ }

  validates :url_from,
            uniqueness: { scope: :site_id },
            allow_nil: true,
            if: -> { Rails.application.config.folio_url_redirects_per_site }

  validates :url_from,
            uniqueness: true,
            allow_nil: true,
            if: -> { !Rails.application.config.folio_url_redirects_per_site }

  validates :match_query,
            :pass_query,
            inclusion: { in: [true, false] }

  validates :status_code,
            inclusion: { in: STATUS_CODES.keys },
            presence: true

  validate :validate_url_from_format
  validate :validate_url_loop

  after_commit :refresh_url_redirects_cache

  pg_search_scope :by_query,
                  against: {
                    title: "A",
                    url_from: "B",
                    url_to: "B"
                  },
                  ignoring: :accents,
                  using: {
                    tsearch: { prefix: true }
                  }

  def to_redirect_hash
    query_array = if url_from.present? && url_from.include?("?")
      uri = URI.parse(url_from)
      if uri.query.present?
        Rack::Utils.parse_query(uri.query).map { |k, v| "#{k}=#{v}" }
      else
        []
      end
    else
      []
    end

    { url_to:, match_query:, pass_query:, status_code:, query_array: }
  end

  def self.use_preview_tokens?
    false
  end

  def self.redirect_hash
    if Rails.application.config.folio_url_redirects_enabled
      hash = {}

      if Rails.application.config.folio_url_redirects_per_site
        self.published.includes(:site).order(id: :asc).each do |url_redirect|
          if url_redirect.url_from
            url_from_without_query = url_redirect.url_from.split("?", 2)[0]

            hash[url_redirect.site.env_aware_domain] ||= {}
            hash[url_redirect.site.env_aware_domain][url_from_without_query] ||= []
            hash[url_redirect.site.env_aware_domain][url_from_without_query] << url_redirect.to_redirect_hash
          end
        end

        hash.presence
      else
        hash["*"] ||= {}

        self.published.includes(:site).order(id: :asc).each do |url_redirect|
          url_from_without_query = url_redirect.url_from.split("?", 2)[0]

          hash["*"] ||= {}
          hash["*"][url_from_without_query] ||= []
          hash["*"][url_from_without_query] << url_redirect.to_redirect_hash
        end

        hash if hash["*"].present?
      end
    else
      {}
    end
  end

  def self.hash_cache_key
    [CACHE_KEY_BASE, ENV["CURRENT_RELEASE_COMMIT_HASH"]].join("-")
  end

  def self.cache_aware_redirect_hash
    if Rails.application.config.action_controller.perform_caching
      Rails.cache.fetch(hash_cache_key, expires_in: CACHE_KEY_EXPIRES_IN) do
        redirect_hash
      end
    else
      redirect_hash
    end
  end

  def self.get_status_code_and_url(env_path:, env_query:, value:)
    targets_ary = value[env_path]

    return if targets_ary.blank?

    query_array = if env_query.present?
      Rack::Utils.parse_query(env_query).map { |k, v| "#{k}=#{v}" }
    else
      []
    end

    valid_targets = targets_ary.select do |target|
      if target[:match_query]
        if query_array.size > target[:query_array].size
          (query_array - target[:query_array]).empty?
        else
          (target[:query_array] - query_array).empty?
        end
      else
        if target[:query_array].present?
          (target[:query_array] - query_array).empty?
        else
          true
        end
      end
    end

    target = valid_targets.sort_by { |t| t[:query_array].size }.last

    if target
      url = if env_query.present? && target[:pass_query]
        url_to_uri = URI.parse(target[:url_to])

        url_to_uri_query_h = Rack::Utils.parse_query(url_to_uri.query)
        env_query_h = Rack::Utils.parse_query(env_query)

        final_query_h = env_query_h.merge(url_to_uri_query_h)

        if final_query_h.present?
          "#{target[:url_to].split("?", 2)[0]}?#{final_query_h.to_query}"
        else
          target[:url_to]
        end
      else
        target[:url_to]
      end

      [target[:status_code], url]
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
          status_code, url = get_status_code_and_url(env_path: env["PATH_INFO"],
                                                     env_query: env["QUERY_STRING"],
                                                     value:)

          if status_code && url
            # store _turbolinks_location so that Turbolinks change URL
            # see https://github.com/turbolinks/turbolinks-rails/blob/4fffc808b437936808f0888a87b1a1ae1bbcb1cd/lib/turbolinks/redirection.rb#L43
            if env["rack.session"]
              env["rack.session"][:_turbolinks_location] = url
            end

            [status_code, { "Location" => url }, []]
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

    def validate_url_from_format
      return if url_from.blank?

      if url_from.start_with?("/")
        if url_from.start_with?("/console")
          errors.add(:url_from, :cannot_start_with_console)
        end
      else
        errors.add(:url_from, :must_be_relative)
      end
    end

    def refresh_url_redirects_cache
      Rails.cache.delete(self.class.hash_cache_key)
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
