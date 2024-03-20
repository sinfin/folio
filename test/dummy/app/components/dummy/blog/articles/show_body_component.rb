# frozen_string_literal: true

class Dummy::Blog::Articles::ShowBodyComponent < ApplicationComponent
  include Folio::AtomsHelper

  def initialize(article:, articles:)
    @article = article

    articles_a = articles.to_a

    # TODO: select correct recommended articles
    articles_a.shift
    @recommended_articles = articles_a.shift
  end
end
