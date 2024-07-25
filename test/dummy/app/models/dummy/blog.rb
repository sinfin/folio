# frozen_string_literal: true

module Dummy::Blog
  ARTICLE_PAGY_ITEMS = 12
  TOPICS_PARAM = :t

  def self.table_name_prefix
    "dummy_blog_"
  end

  def self.available_locales
    I18n.available_locales.map(&:to_s)
  end

  def self.article_includes
    [:published_topics, :published_authors, cover_placement: :file]
  end
end
