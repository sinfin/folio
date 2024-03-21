# frozen_string_literal: true

class Dummy::Blog::Articles::IndexComponent < ApplicationComponent
  def initialize(articles:, pagy: nil, topics: nil)
    @pagy = pagy
    @topics = topics

    articles_a = articles.to_a

    if active_pagy?
      @secondary_articles = articles_a
    else
      @main_articles = articles_a
    end
  end

  def active_pagy?
    @active_pagy ||= @pagy && @pagy.page != 1
  end
end
