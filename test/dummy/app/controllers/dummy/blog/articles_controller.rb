# frozen_string_literal: true

class Dummy::Blog::ArticlesController < ApplicationController
  def index
    folio_run_unless_cached(["blog/articles#index"] + cache_key_base) do
      articles = Dummy::Blog::Article.published
                                     .ordered
                                     .by_locale(I18n.locale)
                                     .includes(Dummy::Blog.article_includes)

      @pagy, @articles = pagy(articles, items: Dummy::Blog::ARTICLE_PAGY_ITEMS)

      @topics = Dummy::Blog::Topic.published
                                  .by_locale(I18n.locale)
                                  .with_published_articles
                                  .ordered
                                  .limit(20)
    end
  end

  def show
    folio_run_unless_cached(["blog/articles#show", params[:id]] + cache_key_base) do
      @article = Dummy::Blog::Article.published_or_preview_token(params[Folio::Publishable::PREVIEW_PARAM_NAME])
                                     .by_locale(I18n.locale)
                                     .friendly.find(params[:id])

      set_meta_variables(@article)

      force_correct_path(url_for(@article))

      articles = Dummy::Blog::Article.published
                                     .ordered
                                     .where.not(id: @article.id)
                                     .by_locale(I18n.locale)
                                     .includes(Dummy::Blog.article_includes)

      @articles = pagy(articles, items: 3)
    end
  end
end
