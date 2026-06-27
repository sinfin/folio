# frozen_string_literal: true

class Dummy::Blog::TopicArticleLink < ApplicationRecord
  include Folio::Positionable

  belongs_to :article, class_name: "Dummy::Blog::Article",
                       foreign_key: :dummy_blog_article_id,
                       inverse_of: :topic_article_links

  belongs_to :topic, class_name: "Dummy::Blog::Topic",
                     foreign_key: :dummy_blog_topic_id,
                     inverse_of: :topic_article_links,
                     counter_cache: :articles_count

  validates :dummy_blog_topic_id,
            uniqueness: { scope: :dummy_blog_article_id }

  validate :validate_matching_locales_and_sites

  def positionable_last_record
    if article
      article.topic_article_links.last
    end
  end

  private
    def validate_matching_locales_and_sites
      if article && topic
        if article.locale != topic.locale
          errors.add(:base, :invalid_locales)
        end

        if article.site_id && topic.site_id && article.site_id != topic.site_id
          errors.add(:topic, :not_from_same_site)
        end
      end
    end
end
