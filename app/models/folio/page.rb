# frozen_string_literal: true

class Folio::Page < Folio::ApplicationRecord
  extend FriendlyId
  extend Folio::InheritenceBaseNaming
  include PgSearch::Model
  include Folio::Taggable
  include Folio::HasAttachments
  include Folio::ReferencedFromMenuItems
  include Folio::Publishable::WithDate
  include Folio::Sitemap::Base
  include Folio::Transportable::Model

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

  if Rails.application.config.folio_pages_translations
    include Folio::Translatable
  end

  if Rails.application.config.folio_pages_ancestry
    include Folio::HasAncestry
    include Folio::HasAncestrySlug
  end

  if Rails.application.config.folio_using_traco
    include Folio::TracoSluggable
    include Folio::HasAtoms::Localized

    friendly_id :title, use: %i[slugged history simple_i18n]

    translates :title, :perex, :slug, :meta_title, :meta_description

    I18n.available_locales.each do |locale|
      validates "title_#{locale}".to_sym,
                presence: true
    end
  else
    include Folio::HasAtoms::Basic

    friendly_id :title, use: %i[slugged history]

    validates :slug,
              presence: true,
              uniqueness: true

    validates :title,
              presence: true
  end

  # Scopes
  scope :ordered,  -> { order(position: :asc, created_at: :asc) }
  scope :featured,  -> { where(featured: true) }

  scope :by_type, -> (type) {
    if type == "Folio::Page"
      where(type: [type, nil])
    else
      where(type: type)
    end
  }

  def self.by_query_associated_against
    if Rails.application.config.folio_using_traco
      h = {}
      I18n.available_locales.each do |locale|
        h["#{locale}_atoms".to_sym] = %i[data_for_search]
      end
      h

      h.merge(
        file_placements: %i[title alt],
      )
    else
      {
        atoms: %i[data_for_search],
        file_placements: %i[title alt],
      }
    end
  end

  # Multi-search
  multisearchable against: begin
                    if Rails.application.config.folio_using_traco &&
                       ActiveRecord::Base.connection.table_exists?("folio_pages")
                      I18n.available_locales.map do |locale|
                        "title_#{locale}"
                      end
                    else
                      [:title]
                    end
                  rescue ActiveRecord::NoDatabaseError
                    [:title]
                  end,
                  ignoring: :accents,
                  additional_attributes: -> (page) { { searchable_type: "Folio::Page" } }

  pg_search_scope :by_query,
                  against: begin
                    if Rails.application.config.folio_using_traco && ActiveRecord::Base.connection.table_exists?("folio_pages")
                      weighted = {}
                      self.column_names.each do |column|
                        if /\A(title|perex)_/.match?(column)
                          if /title/.match?(column)
                            weighted[column] = "A"
                          elsif /perex/.match?(column)
                            weighted[column] = "B"
                          else
                            weighted[column] = "C"
                          end
                        end
                      end
                      weighted
                    else
                      {
                        title: "A",
                        perex: "B",
                      }
                    end
                  rescue ActiveRecord::NoDatabaseError
                    {
                      title: "A",
                      perex: "B",
                    }
                  end,
                  associated_against: self.by_query_associated_against,
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
    "folio/pages/show"
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
end

# == Schema Information
#
# Table name: folio_pages
#
#  id               :bigint(8)        not null, primary key
#  title            :string
#  slug             :string
#  perex            :text
#  meta_title       :string(512)
#  meta_description :text
#  ancestry         :string
#  type             :string
#  featured         :boolean
#  position         :integer
#  published        :boolean
#  published_at     :datetime
#  original_id      :integer
#  locale           :string(6)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  ancestry_slug    :string
#
# Indexes
#
#  index_folio_pages_on_ancestry      (ancestry)
#  index_folio_pages_on_featured      (featured)
#  index_folio_pages_on_locale        (locale)
#  index_folio_pages_on_original_id   (original_id)
#  index_folio_pages_on_position      (position)
#  index_folio_pages_on_published     (published)
#  index_folio_pages_on_published_at  (published_at)
#  index_folio_pages_on_slug          (slug)
#  index_folio_pages_on_type          (type)
#
