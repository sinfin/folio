# frozen_string_literal: true

class Dummy::Blog::Articles::CardsComponent < ApplicationComponent
  def initialize(articles:, size: :md)
    @articles = articles
    @size = size
  end
end
