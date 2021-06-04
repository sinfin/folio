# frozen_string_literal: true

class Dummy::Blog::Article < ApplicationRecord
  include Folio::FriendlyId
  include Folio::HasAttachments
  include Folio::Publishable::WithDate
  include Folio::HasAtoms::Basic

  has_many :topic_article_links, -> { ordered },
                                    class_name: "Dummy::Blog::TopicArticleLink",
                                    inverse_of: :article,
                                    foreign_key: :dummy_blog_article_id,
                                    dependent: :destroy

  accepts_nested_attributes_for :topic_article_links, allow_destroy: true,
                                                         reject_if: :all_blank

  has_many :topics, through: :topic_article_links, source: :topic
  has_many :published_topics, -> { published },
                              through: :topic_article_links,
                              source: :topic

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

  scope :by_topic, -> (topic) do
    ids = Dummy::Blog::TopicArticleLink.select(:dummy_blog_article_id)
                                          .where(topic: topic)

    where(id: ids)
  end

  scope :by_topic_slug, -> (slug) do
    topic = Dummy::Blog::Topic.find_by(slug: slug)

    if topic
      by_topic(topic)
    else
      none
    end
  end

  def published_at_with_fallback
    published_at || created_at
  end

  private
    def validate_matching_locales
      unless topic_article_links.all?(&:valid?)
        errors.add(:locale, :doesnt_match_topics)
      end
    end
end

# == Schema Information
#
# Table name: dummy_blog_articles
#
#  id               :bigint(8)        not null, primary key
#  title            :string
#  slug             :string
#  perex            :text
#  locale           :string           default("cs")
#  meta_title       :string
#  meta_description :text
#  featured         :boolean
#  published        :boolean
#  published_at     :datetime
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_dummy_blog_articles_on_featured      (featured)
#  index_dummy_blog_articles_on_locale        (locale)
#  index_dummy_blog_articles_on_published     (published)
#  index_dummy_blog_articles_on_published_at  (published_at)
#  index_dummy_blog_articles_on_slug          (slug)
#
