# frozen_string_literal: true

class Dummy::Blog::TopicsController < ApplicationController
  def show
    folio_run_unless_cached(["blog/topics#index", params[:page]] + cache_key_base) do
      @topic = Dummy::Blog::Topic.published_or_preview_token(params[Folio::Publishable::PREVIEW_PARAM_NAME])
                                 .by_locale(I18n.locale)
                                 .by_site(Folio::Current.site)
                                 .friendly.find(params[:id])

      articles = @topic.published_articles
                       .by_site(Folio::Current.site)
                       .ordered
                       .includes(Dummy::Blog.article_includes)

      @pagy, @articles = pagy(articles, items: Dummy::Blog::ARTICLE_PAGY_ITEMS)

      force_correct_path(url_for(@topic))
    end
  end
end
