# frozen_string_literal: true

class Dummy::Blog::AuthorArticleLink < ApplicationRecord
  include Folio::Positionable

  belongs_to :article, class_name: "Dummy::Blog::Article",
                       foreign_key: :dummy_blog_article_id,
                       inverse_of: :author_article_links

  belongs_to :author, class_name: "Dummy::Blog::Author",
                      foreign_key: :dummy_blog_author_id,
                      inverse_of: :author_article_links,
                      counter_cache: :articles_count

  validates :dummy_blog_author_id,
            uniqueness: { scope: :dummy_blog_article_id }

  validate :validate_matching_locales_and_sites

  def positionable_last_record
    if article
      article.author_article_links.last
    end
  end

  private
    def validate_matching_locales_and_sites
      if article && author
        if article.locale != author.locale
          errors.add(:base, :invalid_locales)
        end

        if article.site_id && author.site_id && article.site_id != author.site_id
          errors.add(:author, :not_from_same_site)
        end
      end
    end
end

# == Schema Information
#
# Table name: dummy_blog_author_article_links
#
#  id                    :bigint(8)        not null, primary key
#  dummy_blog_author_id   :bigint(8)
#  dummy_blog_article_id :bigint(8)
#  position              :integer
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#
# Indexes
#
#  dummy_blog_author_article_links_a_id  (dummy_blog_article_id)
#  dummy_blog_author_article_links_t_id  (dummy_blog_author_id)
#
