module Folio
  class Node < ApplicationRecord
    extend FriendlyId

    # Relations
    has_ancestry
    belongs_to :site, class_name: "Folio::Site"
    friendly_id :title, use: [:slugged, :scoped, :history], :scope => [:site]

    # Validations
    validates :title, :slug, :locale, presence: true
    validates :slug, uniqueness: { scope: :site_id }

    # Scopes
    scope :featured,  -> { where(featured: true) }
    scope :ordered,   -> { order(position: :asc) }
    scope :published, -> {
      ordered
        .where('published_at IS NOT NULL')
        .where('published_at <= ?', Time.now)
    }

    before_validation do
      self.site = self.parent.site unless self.parent.blank?
    end
  end
end
