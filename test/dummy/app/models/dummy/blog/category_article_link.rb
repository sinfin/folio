# frozen_string_literal: true

class Dummy::Blog::CategoryArticleLink < ApplicationRecord
  include Folio::Positionable

  belongs_to :article, class_name: "Dummy::Blog::Article",
                       foreign_key: :dummy_blog_article_id,
                       inverse_of: :category_article_links

  belongs_to :category, class_name: "Dummy::Blog::Category",
                        foreign_key: :dummy_blog_category_id,
                        inverse_of: :category_article_links

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
