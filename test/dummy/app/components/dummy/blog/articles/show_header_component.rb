# frozen_string_literal: true

class Dummy::Blog::Articles::ShowHeaderComponent < ApplicationComponent
  def initialize(article:)
    @article = article
  end
end
