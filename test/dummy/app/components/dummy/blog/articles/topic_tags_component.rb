# frozen_string_literal: true

class Dummy::Blog::Articles::TopicTagsComponent < ApplicationComponent
  def initialize(article:, size: :md)
    @size = size
    @article = article
    @topics = @article.published_topics
  end

  def render?
    @topics.present?
  end
end
