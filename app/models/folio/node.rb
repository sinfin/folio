# frozen_string_literal: true

class Folio::Node < Folio::ApplicationRecord
  extend FriendlyId
  include PgSearch::Model
  include Folio::Taggable
  include Folio::HasAtoms
  include Folio::HasAttachments
  include Folio::ReferencedFromMenuItems
  include Folio::Publishable::WithDate

  # Relations
  has_ancestry touch: true

  has_many :node_translations, class_name: 'Folio::NodeTranslation',
                               foreign_key: :original_id,
                               dependent: :destroy

  if Rails.application.config.folio_using_traco
    include Folio::TracoSluggable

    friendly_id :title, use: %i[slugged scoped history simple_i18n],
                        scope: [:ancestry]

    translates :title, :perex, :content, :slug, :meta_title, :meta_description

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
    validates :slug,
              presence: true,
              uniqueness: { scope: [:locale, :ancestry] }
  end

  validate :validate_allowed_type,
           if: :has_parent?

  # Callbacks
  before_save :set_position
  before_save :publish_now, if: :published_changed?

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
  scope :original,  -> { where.not(type: 'Folio::NodeTranslation') }
  scope :ordered,  -> { order(position: :asc, created_at: :asc) }
  scope :featured,  -> { where(featured: true) }
  scope :with_locale, -> (locale) { where(locale: locale)   }

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

  scope :by_type, -> (type) {
    case type
    when 'page'
      where(type: Folio::Page.recursive_subclasses.map(&:to_s))
    when 'category'
      where(type: Folio::Category.recursive_subclasses.map(&:to_s))
    else
      where(nil)
    end
  }

  # Multi-search
  multisearchable against: [ :title, :perex, :content, :atom_contents ],
                  if: :searchable?,
                  ignoring: :accents

  pg_search_scope :by_query,
                  against: begin
                    if Rails.application.config.folio_using_traco
                      weighted = {}
                      self.column_names.each do |column|
                        if /\A(title|content|perex)_/.match?(column)
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
                        content: 'C',
                      }
                    end
                  end,
                  associated_against: {
                    atoms: Folio::Atom.text_fields,
                    file_placements: %i[title alt],
                  },
                  ignoring: :accents,
                  using: {
                    tsearch: { prefix: true }
                  }

  def self.arrange_as_array(options = {}, hash = nil)
    hash ||= original.arrange(options)

    arr = []
    hash.each do |node, children|
      arr << node
      arr += arrange_as_array(options, children) unless children.empty?
    end
    arr
  end

  def self.additional_params
    []
  end
  delegate :additional_params, to: :class

  def to_label
    self.title
  end

  def name_depth
    "#{'&nbsp;' * self.depth} #{self.to_label}".html_safe
  end

  def console_caret_icon
    'caret-right'
  end

  # override in subclasses
  def searchable?
    published?
  end

  def self.view_name
    false
  end

  def self.allowed_child_types
    nil
  end

  def self.console_selectable?
    to_s != 'Folio::Node'
  end

  def cast
    if self.type == 'Folio::NodeTranslation'
      self.becomes(self.node_original.class)
    else
      self
    end
  end

  def children
    if self.type == 'Folio::NodeTranslation'
      self.node_original.children
    else
      super
    end
  end

  # FIXME: quick fix to make it work on production
  belongs_to :node_original, class_name: 'Folio::Node', foreign_key: :original_id, optional: true
  def original
    if self.type == 'Folio::NodeTranslation'
      self.node_original
    else
      self
    end
  end

  def translations
    node_translations
  end

  def translate(locale = I18n.locale)
    if locale == self.locale.to_sym
      cast
    elsif self.node_translations.published.where(locale: locale).exists?
      self.node_translations.find_by(locale: locale).cast
    else
      nil
    end
  end

  def translate!(locale, attributes = {})
    ActiveRecord::Base.transaction do
      translation = self.dup
      translation.locale = locale
      translation.becomes!(Folio::NodeTranslation)
      translation.original_id = self.id
      translation.published = false

      translation.assign_attributes(attributes)

      # Files
      self.file_placements.find_each do |fp|
        translation.file_placements << fp.dup
      end

      # Files
      if self.cover_placement.present?
        translation.cover_placement = self.cover_placement.dup
      end

      # TODO: Atoms
      self.atoms.find_each do |atom|
        atom_translation = atom.dup
        atom.file_placements.find_each do |fp|
          atom_translation.file_placements << fp.dup
        end
        translation.atoms << atom_translation
      end

      translation.save!

      translation
    end
  end

  def only_published
    self if published?
  end

  def translation?
    type == 'Folio::NodeTranslation'
  end

  private

    # before_save
    def publish_now
      self.published_at = Time.now if published? && published_at.nil?
    end

    # before_create
    def set_position
      if self.position.nil?
        last = self.siblings.ordered.last
        self.position = !last.nil? ? last.position + 1 : 0
      end
    end

    # custom Validations
    def validate_allowed_type
      return if self.type == 'Folio::NodeTranslation'
      return if parent.nil? || parent.class.allowed_child_types.nil?

      if parent.class.allowed_child_types.exclude? self.class
        errors.add(:type, 'is not allowed')
      end
    end

    # https://github.com/Casecommons/pg_search/issues/34
    def atom_contents
      atoms.map { |a| [a.title, a.perex, a.content] }.flatten.compact.join(' ')
    end
end

if Rails.env.development?
  Dir["#{Folio::Engine.root}/app/models/folio/node_translation.rb"].each do |file|
    require_dependency file
  end
end

# == Schema Information
#
# Table name: folio_nodes
#
#  id               :bigint(8)        not null, primary key
#  title            :string
#  slug             :string
#  perex            :text
#  content          :text
#  meta_title       :string(512)
#  meta_description :text
#  code             :string
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
#  index_folio_nodes_on_ancestry      (ancestry)
#  index_folio_nodes_on_code          (code)
#  index_folio_nodes_on_featured      (featured)
#  index_folio_nodes_on_locale        (locale)
#  index_folio_nodes_on_original_id   (original_id)
#  index_folio_nodes_on_position      (position)
#  index_folio_nodes_on_published     (published)
#  index_folio_nodes_on_published_at  (published_at)
#  index_folio_nodes_on_slug          (slug)
#  index_folio_nodes_on_type          (type)
#
