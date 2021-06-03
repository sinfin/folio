# frozen_string_literal: true

class Dummy::Blog::Article < ApplicationRecord
  include Folio::FriendlyId
  include Folio::HasAttachments
  include Folio::Publishable::WithDate
  include Folio::HasAtoms::Basic

  belongs_to :primary_category, class_name: "Dummy::Blog::Category",
                                inverse_of: :primary_articles,
                                foreign_key: :primary_category_id,
                                optional: true

  has_and_belongs_to_many :categories,
                          -> { ordered },
                          foreign_key: :dummy_blog_article_id,
                          association_foreign_key: :dummy_blog_category_id

  has_and_belongs_to_many :published_categories,
                          -> { published.ordered },
                          class_name: "Dummy::Blog::Category",
                          foreign_key: :dummy_blog_article_id,
                          association_foreign_key: :dummy_blog_category_id

  # Validations
  validates :title,
            :slug,
            :perex,
            presence: true
  validates :slug, uniqueness: true

  validates :locale,
            presence: Dummy::Blog.available_locales

  after_save :add_primary_category_to_categories
  after_save :touch_categories

  # Scopes
  pg_search_scope :by_query,
                  against: {
                    title: "A",
                    perex: "B"
                  },
                  ignoring: :accents,
                  using: {
                    tsearch: { prefix: true }
                  }

  multisearchable against: [:title],
                  ignoring: :accents

  scope :ordered, -> { order(published_at: :desc) }
  scope :featured, -> { where(featured: true) }
  scope :by_locale, -> (locale) { where(locale: locale) }
  scope :by_category_id, -> (id) { joins(:categories).where(dummy_blog_categories: { id: id }) }

  def published_at_with_fallback
    published_at || created_at
  end

  private
    def add_primary_category_to_categories
      if primary_category && !categories.exists?(id: primary_category.id)
        self.categories << primary_category
      end
    end

    def touch_categories
      categories.find_each(&:touch)
    end
end
