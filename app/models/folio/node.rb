# frozen_string_literal: true

module Folio
  class Node < ApplicationRecord
    extend FriendlyId
    include Taggable
    include PgSearch
    include HasAtoms
    include HasAttachments
    include Publishable::WithDate

    # Relations
    has_ancestry
    belongs_to :site, class_name: 'Folio::Site'
    friendly_id :title, use: %i[slugged scoped history], scope: [:site, :locale, :ancestry]

    has_many :node_translations, class_name: 'Folio::NodeTranslation', foreign_key: :original_id, dependent: :destroy

    # Validations
    validates :title, :slug, :locale, presence: true
    validates :slug, uniqueness: { scope: [:site_id, :locale, :ancestry] }
    validates :locale, inclusion: { in: proc { I18n.available_locales.map(&:to_s) } }
    validate :allowed_type, if: :has_parent?

    # Callbacks
    before_save :set_position
    before_save :publish_now, if: :published_changed?

    before_validation do
      # FIXME: breaks without a parent
      if site.nil?
        if parent.blank?
          self.site = Site.first
        else
          self.site = parent.site
        end
      end
      self.locale = site.locale if locale.nil?
    end

    # Multi-search
    include PgSearch
    multisearchable against: [ :title, :perex ], if: :searchable?, ignoring: :accents
    # pg_search_scope :search, against: [:title, :name], using: { tsearch: { prefix: true } }

    # Scopes
    scope :original,  -> { where.not(type: 'Folio::NodeTranslation') }
    scope :ordered,  -> { order('position ASC, created_at ASC') }
    scope :featured,  -> { where(featured: true) }
    scope :with_locale, -> (locale) { where(locale: locale)   }

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
      false
    end

    def self.view_name
      false
    end

    def self.allowed_child_types
      nil
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
        cast
      end
    end

    def translate!(locale, attributes = {})
      ActiveRecord::Base.transaction do
        translation = self.dup
        translation.locale = locale
        translation.becomes!(NodeTranslation)
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
      def allowed_type
        return if self.type == 'Folio::NodeTranslation'
        return if parent.nil? || parent.class.allowed_child_types.nil?

        if parent.class.allowed_child_types.exclude? self.class
          errors.add(:type, 'is not allowed')
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
