# frozen_string_literal: true

class Dummy::Blog::Articles::CardsComponent < ApplicationComponent
  def initialize(articles:, size: :md, hero_size: nil, column_classes: "col-12")
    @articles = articles
    @size = size
    @hero_size = hero_size
    @column_classes = column_classes
  end
end
