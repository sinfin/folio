# frozen_string_literal: true

class Dummy::Blog::Articles::CardComponent < ApplicationComponent
  SMALL_COVER_SIZE = "80x80#"
  MEDIUM_COVER_SIZE = "377x230#"
  LARGE_COVER_SIZE = "592x278#"

  def initialize(article:, size: :md)
    @article = article
    @size = size
  end

  def cover_size
    if @size == :lg
      LARGE_COVER_SIZE
    elsif @size == :md
      MEDIUM_COVER_SIZE
    else
      SMALL_COVER_SIZE
    end
  end

  def topics
    @topics ||= @article.published_topics.to_a.first(3).map do |topic|
      {
        href: url_for(topic),
        label: topic.to_label,
      }
    end
  end
end
