# frozen_string_literal: true

class Dummy::Blog::Articles::IndexComponent < ApplicationComponent
  include Pagy::Backend

  def initialize(articles_scope: nil, title: nil, perex: nil, author: nil, topic: nil)
    @articles_scope = articles_scope || Dummy::Blog::Article
    @title = title
    @perex = perex
    @author = author
    @topic = topic
    @url_base = author || Dummy::Blog::Article
  end

  def size_of_first
    return nil if @pagy && @pagy.page != 1
    return nil if params[Dummy::Blog::TOPICS_PARAM].present?
    :l
  end

  def before_render
    articles = @articles_scope.published
                              .by_locale(locale)
                              .by_site(Folio::Current.site)

    @topics = if @topic
      nil
    else
      scope = Dummy::Blog::Topic.published
                                  .by_locale(locale)
                                  .by_site(Folio::Current.site)
                                  .ordered

      if @author
        topic_ids = Dummy::Blog::TopicArticleLink.where(dummy_blog_article_id: articles.select(:id)).select(:dummy_blog_topic_id)
        scope.where(id: topic_ids)
      else
        scope.with_published_articles
      end

      scope.ordered
                   .limit(50)
    end

    articles = articles.public_filter_by_topics(params[Dummy::Blog::TOPICS_PARAM])
                       .includes(Dummy::Blog.article_includes)
                       .ordered

    if params[:page].blank? || !params[:page].match?(/\A\d+\z/) || params[:page].to_i <= 1
      @pagy, @articles = pagy(articles, items: Dummy::Blog::ARTICLE_PAGY_ITEMS + 1)
    else
      @pagy, @articles = pagy(articles.offset(1), items: Dummy::Blog::ARTICLE_PAGY_ITEMS, outset: 1)
    end
  end
end
