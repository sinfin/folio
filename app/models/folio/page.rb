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

  self.table_name = 'folio_pages'

  # Relations
  has_ancestry touch: true

  belongs_to :original, class_name: 'Folio::Page',
                        foreign_key: :original_id,
                        optional: true

  has_many :translations, class_name: 'Folio::Page',
                          foreign_key: :original_id,
                          inverse_of: :original,
                          dependent: :destroy

  if Rails.application.config.folio_using_traco
    include Folio::TracoSluggable

    friendly_id :title, use: %i[slugged scoped history simple_i18n],
                        scope: [:ancestry]

    translates :title, :perex, :slug, :meta_title, :meta_description

    I18n.available_locales.each do |locale|
      validates "title_#{locale}".to_sym,
                presence: true

      validates "slug_#{locale}".to_sym,
                uniqueness: { scope: [:ancestry] }
    end
  else
    friendly_id :title, use: %i[slugged scoped history],
                        scope: [:locale, :ancestry]

    validates :title,
              presence: true

    validates :locale,
              presence: true,
              inclusion: { in: proc { I18n.available_locales.map(&:to_s) } }

    validates :locale,
              uniqueness: { scope: :original_id },
              if: :original_id

    validates :slug,
              presence: true,
              uniqueness: { scope: [:locale, :ancestry] }
  end

  validate :validate_allowed_type,
           if: :has_parent?

  # Callbacks
  before_save :set_position

  before_validation do
    if locale.nil?
      if Folio::Site.exists?
        self.locale = Folio::Site.instance.locale
      else
        self.locale = I18n.locale
      end
    end
  end

  # Scopes
  scope :original, -> { where(original_id: nil) }
  scope :ordered,  -> { order(position: :asc, created_at: :asc) }
  scope :featured,  -> { where(featured: true) }
  scope :by_locale, -> (locale) { where(locale: locale)   }

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
                    atoms: Folio::Atom.text_fields,
                    file_placements: %i[title alt],
                  },
                  ignoring: :accents

  def self.arrange_as_array(options = {}, hash = nil)
    hash ||= original.arrange(options)

    arr = []
    hash.each do |page, children|
      arr << page
      arr += arrange_as_array(options, children) unless children.empty?
    end
    arr
  end

  def to_label
    self.title
  end

  def name_depth
    "#{'&nbsp;' * self.depth} #{self.to_label}".html_safe
  end

  def self.view_name
    'folio/pages/show'
  end

  def self.allowed_child_types
    nil
  end

  # TODO
  def translate(locale)
    return nil unless persisted?
    existing = translation(locale)
    return existing if existing.present?

    translation = dup
    translation.locale = locale
    translation.original_id = id
    translation.published = false

    # Files
    file_placements.find_each do |fp|
      translation.file_placements << fp.dup
    end

    # Atoms
    atoms.find_each do |atom|
      atom_translation = atom.dup
      atom.file_placements.find_each do |fp|
        atom_translation.file_placements << fp.dup
      end
      translation.atoms << atom_translation
    end

    translation
  end

  def translate!(locale)
    ActiveRecord::Base.transaction do
      translation = translate(locale)
      translation.save!
      translation
    end
  end

  def translation?
    original.present?
  end

  def translation(locale = I18n.locale)
    translations.find_by(locale: locale)
  end

  private

    # before_create
    def set_position
      if self.position.nil?
        last = self.siblings.ordered.last
        self.position = !last.nil? ? last.position + 1 : 0
      end
    end

    # custom Validations
    def validate_allowed_type
      return if parent.nil? || parent.class.allowed_child_types.nil?

      if parent.class.allowed_child_types.exclude? self.class
        errors.add(:type, 'is not allowed')
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
