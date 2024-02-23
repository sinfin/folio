# frozen_string_literal: true

class Dummy::Blog::Articles::CardComponent < ApplicationComponent
  def initialize(article:, size: :md)
    @article = article
    @size = size
  end
end
