# frozen_string_literal: true

class Dummy::Blog::Articles::ShowBodyComponent < ApplicationComponent
  include Folio::AtomsHelper

  def initialize(article:, recommended_articles: nil)
    @article = article
    @recommended_articles = recommended_articles
  end
end
