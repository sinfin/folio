# frozen_string_literal: true

module Folio
  class Node < ApplicationRecord
    extend FriendlyId

    # Relations
    has_ancestry
    belongs_to :site, class_name: 'Folio::Site'
    friendly_id :title, use: %i[slugged scoped history], scope: [:site]
    has_many :file_placements, class_name: 'Folio::FilePlacement'
    has_many :translations, class_name: 'Folio::NodeTranslation'

    # Validations
    def self.types
      %w"Folio::Page Folio::Category"
    end
    validates :title, :slug, :locale, presence: true
    validates :slug, uniqueness: { scope: :site_id }
    validates :type, inclusion: { in: types }

    # Scopes
    scope :featured,  -> { where(featured: true) }
    scope :ordered,   -> { order(position: :asc) }
    scope :published, -> {
      ordered
        .where('published', true)
        .where('published_at IS NOT NULL')
        .where('published_at <= ?', Time.now)
    }

    before_validation do
      self.site = parent.site unless parent.blank?
    end

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

    def cast
      self
    end

    def translate(locale)
      case locale
      when locale == self.locale
        cast
      when self.translations.where(locale: locale).exists?
        self.translations.find_by(locale: locale).cast
      else
        cast
      end
    end
  end
end
