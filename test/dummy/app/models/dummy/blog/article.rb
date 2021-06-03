# frozen_string_literal: true

class Dummy::Blog::Article < ApplicationRecord
  include Folio::FriendlyId
  include Folio::HasAttachments
  include Folio::Publishable::WithDate
  include Folio::HasAtoms::Basic

  has_many :category_article_links, -> { ordered },
                                    class_name: "Dummy::Blog::CategoryArticleLink",
                                    inverse_of: :article,
                                    foreign_key: :dummy_blog_article_id,
                                    dependent: :destroy

  accepts_nested_attributes_for :category_article_links, allow_destroy: true,
                                                         reject_if: :all_blank

  has_many :categories, through: :category_article_links, source: :category

  validates :title,
            :perex,
            presence: true

  validates :locale,
            inclusion: { in: Dummy::Blog.available_locales }

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

  scope :by_category, -> (category) do
    ids = Dummy::Blog::ItemArtistLink.select(:dummy_blog_article_id)
                                     .where(category: category)

    where(id: ids)
  end

  scope :by_category_slug, -> (slug) do
    category = Dummy::Blog::Category.find_by(slug: slug)

    if category
      by_category(category)
    else
      none
    end
  end

  def published_at_with_fallback
    published_at || created_at
  end
end
