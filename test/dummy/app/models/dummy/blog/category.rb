# frozen_string_literal: true

class Dummy::Blog::Category < ApplicationRecord
  include Folio::FriendlyId
  include Folio::HasAttachments
  include Folio::Publishable::Basic

  has_many :primary_articles, class_name: "Dummy::Blog::Article",
                              inverse_of: :primary_category,
                              foreign_key: :primary_category_id,
                              dependent: :nullify

  has_and_belongs_to_many :articles,
                          -> { ordered },
                          class_name: "Dummy::Blog::Article",
                          foreign_key: :dummy_blog_category_id,
                          association_foreign_key: :dummy_blog_article_id

  has_and_belongs_to_many :published_articles,
                          -> { published.ordered },
                          class_name: "Dummy::Blog::Article",
                          foreign_key: :dummy_blog_category_id,
                          association_foreign_key: :dummy_blog_article_id

  # Validations
  validates :title,
            :slug,
            presence: true
  validates :slug, uniqueness: true

  validates :locale,
            presence: Dummy::Blog.available_locales

  after_save :update_articles_count, prepend: true
  after_touch :update_articles_count, prepend: true

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

  scope :by_locale, -> (locale) { where(locale: locale) }
  scope :featured, -> { where(featured: true) }
  scope :ordered, -> { order(title: :asc) }

  private
    def update_articles_count
      update_column(:articles_count, articles.count)
    end
end
