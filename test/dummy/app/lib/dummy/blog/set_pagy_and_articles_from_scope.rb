# frozen_string_literal: true

module Dummy::Blog::SetPagyAndArticlesFromScope
  extend ActiveSupport::Concern

  def set_pagy_and_articles_from_scope(scope)
    if params[:page].blank? || !params[:page].match?(/\A\d+\z/) || params[:page].to_i <= 1
      @pagy, @articles = pagy(scope, items: Dummy::Blog::ARTICLE_PAGY_ITEMS + 1)
    else
      @pagy, @articles = pagy(scope.offset(1), items: Dummy::Blog::ARTICLE_PAGY_ITEMS, outset: 1)
    end
  end
end
