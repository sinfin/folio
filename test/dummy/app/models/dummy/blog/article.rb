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
  has_many :published_categories, -> { published },
                                  through: :category_article_links,
                                  source: :category

  validates :title,
            :perex,
            presence: true

  validates :locale,
            inclusion: { in: Dummy::Blog.available_locales }

  validate :validate_matching_locales

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
    ids = Dummy::Blog::CategoryArticleLink.select(:dummy_blog_article_id)
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

  private
    def validate_matching_locales
      unless category_article_links.all?(&:valid?)
        errors.add(:locale, :doesnt_match_categories)
      end
    end
end

# == Schema Information
#
# Table name: dummy_blog_articles
#
#  id                  :bigint(8)        not null, primary key
#  title               :string
#  slug                :string
#  perex               :text
#  locale              :string           default("cs")
#  meta_title          :string
#  meta_description    :text
#  featured            :boolean
#  published           :boolean
#  published_at        :datetime
#  primary_category_id :bigint(8)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
# Indexes
#
#  index_dummy_blog_articles_on_featured             (featured)
#  index_dummy_blog_articles_on_locale               (locale)
#  index_dummy_blog_articles_on_primary_category_id  (primary_category_id)
#  index_dummy_blog_articles_on_published            (published)
#  index_dummy_blog_articles_on_published_at         (published_at)
#  index_dummy_blog_articles_on_slug                 (slug)
#
