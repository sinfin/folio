# frozen_string_literal: true

class Folio::Page < Folio::ApplicationRecord
  if Rails.application.config.folio_using_traco
    include Folio::BelongsToSite
    const_set(:FRIENDLY_ID_SCOPE, :site_id)
    include Folio::FriendlyIdForTraco

    if Rails.application.config.folio_pages_ancestry
      include Folio::HasAncestry
      include Folio::HasAncestrySlugForTraco
    end
  else
    include Folio::BelongsToSiteAndFriendlyId

    if Rails.application.config.folio_pages_ancestry
      include Folio::HasAncestry
      include Folio::HasAncestrySlug
    end
  end

  extend Folio::InheritenceBaseNaming
  include Folio::HasAttachments
  include Folio::Publishable::WithDate
  include Folio::Sitemap::Base
  include Folio::Taggable
  include Folio::Transportable::Model
  include PgSearch::Model

  if Rails.application.config.folio_pages_audited
    include Folio::Audited

    translated = %i[
      title perex slug meta_title meta_description
    ]
    other = %i[published published_at featured]

    if Rails.application.config.folio_using_traco
      translated = translated.map do |key|
        I18n.available_locales.map do |locale|
          :"#{key}_#{locale}"
        end
      end.flatten
    end

    audited only: translated + other, view_name: :edit
    has_audited_atoms
  end

  if Rails.application.config.folio_using_traco
    include Folio::HasAtoms::Localized

    translates :title, :perex, :slug, :meta_title, :meta_description

    validate :validate_title_for_site_locales
  else
    include Folio::HasAtoms::Basic

    validates :title,
              presence: true
  end

  # Scopes
  scope :ordered,  -> { order(position: :asc, created_at: :asc) }
  scope :featured,  -> { where(featured: true) }

  scope :by_atom_setting_locale, -> (locale) {
    where(locale:)
  }

  scope :by_type, -> (type) {
    if type == "Folio::Page"
      where(type: [type, nil])
    else
      where(type:)
    end
  }

  scope :by_locale, -> (locale) {
    where(locale:)
  }

  before_save :set_atoms_data_for_search

  def self.traco_aware_against(multisearch: false)
    if multisearch
      if Rails.application.config.folio_using_traco
        I18n.available_locales.map { |locale| "title_#{locale}".to_sym }
      else
        %i[title]
      end
    else
      h = {}

      if Rails.application.config.folio_using_traco
        I18n.available_locales.each do |locale|
          h["title_#{locale}".to_sym] = "A"
          h["perex_#{locale}".to_sym] = "B"
        end
      else
        h["title"] = "A"
        h["perex"] = "B"
      end

      h["atoms_data_for_search"] = "C"

      h
    end
  end

  # Multi-search
  multisearchable against: self.traco_aware_against(multisearch: true),
                  ignoring: :accents,
                  additional_attributes: -> (page) { { searchable_type: "Folio::Page" } }

  pg_search_scope :by_query,
                  against: self.traco_aware_against,
                  ignoring: :accents,
                  using: {
                    tsearch: { prefix: true }
                  }

  def to_label
    title
  end

  def to_preview_param
    if Rails.application.config.folio_pages_ancestry
      ancestry_url
    else
      to_param
    end
  end

  def self.view_name
  end

  def self.public_rails_path
    nil
  end

  def self.public?
    if public_rails_path.present?
      false
    else
      true
    end
  end

  private
    def set_atoms_data_for_search
      self.atoms_data_for_search = all_atoms_in_array.filter_map { |a| a.data_for_search }.join(" ").presence
    end

    def validate_title_for_site_locales
      if site.blank?
        errors.add(:site, :blank)
      else
        site.locales.each do |locale|
          title_attr = "title_#{locale}"
          if send(title_attr).blank?
            errors.add(title_attr, :blank)
          end
        end
      end
    end
end

# == Schema Information
#
# Table name: folio_pages
#
#  id                    :bigint(8)        not null, primary key
#  title                 :string
#  slug                  :string
#  perex                 :text
#  meta_title            :string(512)
#  meta_description      :text
#  ancestry              :string
#  type                  :string
#  position              :integer
#  published             :boolean
#  published_at          :datetime
#  original_id           :integer
#  locale                :string(6)
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  ancestry_slug         :string
#  site_id               :bigint(8)
#  atoms_data_for_search :text
#  preview_token         :string
#
# Indexes
#
#  index_folio_pages_on_ancestry      (ancestry)
#  index_folio_pages_on_by_query      ((((setweight(to_tsvector('simple'::regconfig, folio_unaccent(COALESCE((title)::text, ''::text))), 'A'::"char") || setweight(to_tsvector('simple'::regconfig, folio_unaccent(COALESCE(perex, ''::text))), 'B'::"char")) || setweight(to_tsvector('simple'::regconfig, folio_unaccent(COALESCE(atoms_data_for_search, ''::text))), 'C'::"char")))) USING gin
#  index_folio_pages_on_locale        (locale)
#  index_folio_pages_on_original_id   (original_id)
#  index_folio_pages_on_position      (position)
#  index_folio_pages_on_published     (published)
#  index_folio_pages_on_published_at  (published_at)
#  index_folio_pages_on_site_id       (site_id)
#  index_folio_pages_on_slug          (slug)
#  index_folio_pages_on_type          (type)
#
