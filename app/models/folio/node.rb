# frozen_string_literal: true

module Folio
  class Node < ApplicationRecord
    extend FriendlyId

    # Relations
    has_ancestry
    belongs_to :site, class_name: 'Folio::Site'
    friendly_id :title, use: %i[slugged scoped history], scope: [:site]
    has_many :file_placements, class_name: 'Folio::FilePlacement'

    accepts_nested_attributes_for :file_placements, allow_destroy: true

    # Validations
    def self.types
      %w"Folio::Page Folio::Category"
    end
    validates :title, :slug, :locale, presence: true
    validates :slug, uniqueness: { scope: :site_id }
    validates :type, inclusion: { in: types }

    # Callbacks
    before_validation do
      self.site = parent.site if site.nil?
      self.locale = site.locale if locale.nil?
    end

    # Scopes
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

    def to_label
      self.title
    end

    def name_depth
      "#{'&nbsp;' * self.depth} #{self.to_label}".html_safe
    end
  end
end
