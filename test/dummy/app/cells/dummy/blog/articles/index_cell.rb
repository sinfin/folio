# frozen_string_literal: true

class Dummy::Blog::Articles::IndexCell < ApplicationCell
  def show
    if model.present?
      @main_article = model.slice(0)
      @secondary_articles = model.slice(1, 2)
      @small_articles = model.slice(3, -1)

      render
    end
  end
end
