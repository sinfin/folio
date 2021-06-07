# frozen_string_literal: true

class Dummy::Blog::Topic < ApplicationRecord
  include Folio::FriendlyId
  include Folio::HasAttachments
  include Folio::Publishable::Basic

  has_many :topic_article_links, -> { ordered },
                                    class_name: "Dummy::Blog::TopicArticleLink",
                                    inverse_of: :topic,
                                    foreign_key: :dummy_blog_topic_id,
                                    dependent: :destroy

  accepts_nested_attributes_for :topic_article_links, allow_destroy: true,
                                                         reject_if: :all_blank

  has_many :articles, through: :topic_article_links, source: :article
  has_many :published_articles, -> { published },
                                through: :topic_article_links,
                                source: :article

  validates :title,
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

  scope :by_locale, -> (locale) { where(locale: locale) }
  scope :featured, -> { where(featured: true) }
  scope :ordered, -> { order(title: :asc) }
  scope :by_atom_setting_locale, -> (locale) { by_locale(locale) }

  scope :with_published_articles, -> { joins(:published_articles).distinct }
end

# == Schema Information
#
# Table name: dummy_blog_topics
#
#  id               :bigint(8)        not null, primary key
#  title            :string
#  slug             :string
#  perex            :text
#  locale           :string           default("cs")
#  published        :boolean
#  featured         :boolean
#  articles_count   :integer          default(0)
#  position         :integer
#  meta_title       :string
#  meta_description :text
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_dummy_blog_topics_on_featured   (featured)
#  index_dummy_blog_topics_on_locale     (locale)
#  index_dummy_blog_topics_on_position   (position)
#  index_dummy_blog_topics_on_published  (published)
#  index_dummy_blog_topics_on_slug       (slug)
#
