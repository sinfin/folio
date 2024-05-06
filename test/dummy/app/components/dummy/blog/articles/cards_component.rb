# frozen_string_literal: true

class Dummy::Blog::Articles::CardsComponent < ApplicationComponent
  def initialize(articles:, size: :md, hero_size: nil, column_classes: "col-12", container_classes: "col-12", hero_classes: "col-12")
    @size = size
    @hero_size = hero_size
    @column_classes = column_classes
    @container_classes = container_classes
    @hero_classes = hero_classes

    articles_a = articles.to_a

    if @hero_size
      @hero_article = articles_a.shift
      @articles = articles_a
    else
      @articles = articles_a
    end
  end
end
