# frozen_string_literal: true

class Dummy::Blog::Articles::IndexCell < ApplicationCell
  def show
    if model.present?
      @main_article = model[0]
      @secondary_articles = model[1..2]
      @small_articles = model[3..-1]

      render
    end
  end
end
