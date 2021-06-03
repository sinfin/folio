# frozen_string_literal: true

class Dummy::Blog::CategoryArticleLink < ApplicationRecord
  include Folio::Positionable

  belongs_to :article, class_name: "Dummy::Blog::Article",
                       foreign_key: :dummy_blog_article_id,
                       inverse_of: :category_article_links

  belongs_to :category, class_name: "Dummy::Blog::Category",
                        foreign_key: :dummy_blog_category_id,
                        inverse_of: :category_article_links,
                        counter_cache: :articles_count

  validates :dummy_blog_category_id,
            uniqueness: { scope: :dummy_blog_article_id }

  validate :validate_matching_locales

  def positionable_last_record
    if article
      article.category_article_links.last
    end
  end

  private
    def validate_matching_locales
      # TODO
      if article && category && article.locale != category.locale
        errors.add(:base, :invalid_locales)
      end
    end
end

# == Schema Information
#
# Table name: dummy_blog_category_article_links
#
#  id                     :bigint(8)        not null, primary key
#  dummy_blog_category_id :bigint(8)
#  dummy_blog_article_id  :bigint(8)
#  position               :integer
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  dummy_blog_category_article_links_a_id  (dummy_blog_article_id)
#  dummy_blog_category_article_links_c_id  (dummy_blog_category_id)
#
