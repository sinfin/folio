# frozen_string_literal: true

require_dependency 'folio/concerns/taggable'

module Folio
  class Node < ApplicationRecord
    extend FriendlyId
    include Taggable
    include PgSearch

    # Relations
    has_ancestry
    belongs_to :site, class_name: 'Folio::Site'
    friendly_id :title, use: %i[slugged scoped history], scope: [:site, :locale]

    has_many :file_placements, -> { ordered }, class_name: 'Folio::FilePlacement', as: :placement, dependent: :destroy
    has_many :files, through: :file_placements
    has_many :images, source: :file, through: :file_placements
    has_many :documents, source: :file, through: :file_placements

    has_many :node_translations, class_name: 'Folio::NodeTranslation', foreign_key: :original_id, dependent: :destroy
    has_many :atoms, -> { order(:position) }, class_name: 'Folio::Atom', dependent: :destroy

    accepts_nested_attributes_for :file_placements, allow_destroy: true
    accepts_nested_attributes_for :atoms, reject_if: :all_blank, allow_destroy: true

    # Validations
    validates :title, :slug, :locale, presence: true
    validates :slug, uniqueness: { scope: [:site_id, :locale] }
    validates :locale, inclusion: I18n.available_locales.map { |l| l.to_s }

    # Callbacks
    before_validation do
      # FIXME: breaks without a parent
      self.site = parent.site if site.nil?
      self.locale = site.locale if locale.nil?
    end

    # Multi-search
    include PgSearch
    multisearchable against: [ :title, :perex ], if: :searchable?
    # pg_search_scope :search, against: [:title, :name], using: { tsearch: { prefix: true } }

    # Scopes
    scope :original,  -> { where.not(type: 'Folio::NodeTranslation') }
    scope :ordered,  -> { order('position asc, created_at desc') }
    scope :featured,  -> { where(featured: true) }
    scope :ordered,   -> { order(position: :asc) }
    scope :published, -> {
      ordered
        .where('published', true)
        .where('published_at IS NOT NULL')
        .where('published_at <= ?', Time.now)
    }
    scope :unpublished, -> {
      nodes = Folio::Node.arel_table
      ordered
        .where(
          nodes[:published].eq(false)
          .or(nodes[:published_at].eq(nil))
          .or(nodes[:published_at].gt(Time.now))
        )
    }

    scope :by_query, -> (q) {
      if q.present?
        args = ["%#{q}%"] * 3
        where('title ILIKE ? OR perex ILIKE ? OR content ILIKE ?', *args)
        # search_node(args)
      else
        where(nil)
      end
    }

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

    scope :by_parent, -> (parent) { children_of(parent) }

    scope :by_type, -> (type) {
      case type
      when 'page'
        where(type: 'Folio::Page')
      when 'category'
        where(type: 'Folio::Category')
      else
        where(nil)
      end
    }

    def self.arrange_as_array(options = {}, hash = nil)
      hash ||= arrange(options)

      arr = []
      hash.each do |node, children|
        arr << node
        arr += arrange_as_array(options, children) unless children.empty?
      end
      arr
    end

    def additional_params
      []
    end

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
      false
    end

    def self.partial
      false
    end

    def cast
      self
    end

    def original
      self
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
        cast
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
#  id               :integer          not null, primary key
#  site_id          :integer
#  title            :string
#  slug             :string
#  perex            :text
#  content          :text
#  meta_title       :string(512)
#  meta_description :string(1024)
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
#  index_folio_nodes_on_site_id       (site_id)
#  index_folio_nodes_on_slug          (slug)
#  index_folio_nodes_on_type          (type)
#
