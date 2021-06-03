# frozen_string_literal: true

class Dummy::Blog::Category < ApplicationRecord
  include Folio::FriendlyId
  include Folio::HasAttachments
  include Folio::Publishable::Basic

  has_many :category_article_links, -> { ordered },
                                    class_name: "Dummy::Blog::CategoryArticleLink",
                                    inverse_of: :category,
                                    foreign_key: :dummy_blog_category_id,
                                    dependent: :destroy

  accepts_nested_attributes_for :category_article_links, allow_destroy: true,
                                                         reject_if: :all_blank

  has_many :articles, through: :category_article_links, source: :article

  validates :title,
            presence: true

  validates :locale,
            inclusion: { in: Dummy::Blog.available_locales }

  after_save :update_articles_count, prepend: true
  after_touch :update_articles_count, prepend: true

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
