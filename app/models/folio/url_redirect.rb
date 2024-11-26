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

  validates :url_from,
            :url_to,
            presence: true,
            format: { with: /\A(\/|https?:\/\/).+/ }

  validates :url_to,
            :url_from,
            uniqueness: { scope: :site_id },
            if: -> { Rails.application.config.folio_url_redirects_per_site }

  validates :url_to,
            :url_from,
            uniqueness: true,
            if: -> { !Rails.application.config.folio_url_redirects_per_site }

  validates :include_query,
            inclusion: { in: [true, false] }

  validates :status_code,
            inclusion: { in: STATUS_CODES.keys },
            presence: true

  validate :validate_url_loop

  def self.use_preview_tokens?
    false
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
end

# == Schema Information
#
# Table name: folio_url_redirects
#
#  id            :bigint(8)        not null, primary key
#  title         :string
#  url_from      :string
#  url_to        :string
#  status_code   :integer          default(301)
#  published     :boolean          default(TRUE)
#  include_query :boolean          default(FALSE)
#  site_id       :bigint(8)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_folio_url_redirects_on_site_id  (site_id)
#
