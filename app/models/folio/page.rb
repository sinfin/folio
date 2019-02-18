# frozen_string_literal: true

class Folio::Page < Folio::ApplicationRecord
  extend FriendlyId
  extend Folio::InheritenceBaseNaming
  include PgSearch
  include Folio::Taggable
  include Folio::HasAtoms
  include Folio::HasAttachments
  include Folio::ReferencedFromMenuItems
  include Folio::Publishable::WithDate

  if Rails.application.config.folio_pages_translations
    include Folio::Translatable
  end

  if Rails.application.config.folio_pages_ancestry
    include Folio::HasAncestry
  end

  self.table_name = 'folio_pages'

  if Rails.application.config.folio_using_traco
    include Folio::TracoSluggable

    friendly_id :title, use: %i[slugged history simple_i18n]

    translates :title, :perex, :slug, :meta_title, :meta_description

    I18n.available_locales.each do |locale|
      validates "title_#{locale}".to_sym,
                presence: true
    end
  else
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

  scope :by_published, -> (state) {
    case state
    when 'published'
      published
    when 'unpublished'
      unpublished
    else
      where(nil)
    end
  }

  # Multi-search
  multisearchable against: [ :title, :perex, :atom_contents ],
                  ignoring: :accents

  pg_search_scope :by_query,
                  against: begin
                    if Rails.application.config.folio_using_traco
                      weighted = {}
                      self.column_names.each do |column|
                        if /\A(title|perex)_/.match?(column)
                          if /title/.match?(column)
                            weighted[column] = 'A'
                          elsif /perex/.match?(column)
                            weighted[column] = 'B'
                          else
                            weighted[column] = 'C'
                          end
                        end
                      end
                      weighted
                    else
                      {
                        title: 'A',
                        perex: 'B',
                      }
                    end
                  end,
                  associated_against: {
                    atoms: %i[title perex content],
                    file_placements: %i[title alt],
                  },
                  ignoring: :accents

  def to_label
    title
  end

  def self.view_name
    'folio/pages/show'
  end

  def self.atom_locales
    if Rails.application.config.folio_using_traco
      I18n.available_locales
    else
      [I18n.default_locale]
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
