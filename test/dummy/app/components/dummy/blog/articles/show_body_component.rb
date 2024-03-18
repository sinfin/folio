# frozen_string_literal: true

class Dummy::Blog::Articles::ShowBodyComponent < ApplicationComponent
  include Folio::AtomsHelper

  def initialize(article:, articles:)
    @article = article

    articles_a = articles.to_a

    # TODO: select right recommended articles
    articles_a.shift
    articles = articles_a.shift
    @main_recommended_article = articles.first
    @recommended_articles = articles.drop(1)
  end
end
