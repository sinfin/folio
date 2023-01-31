# frozen_string_literal: true

class Dummy::Blog::ArticlesController < ApplicationController
  before_action { @klass = Dummy::Blog::Article }
  before_action :find_article, only: [:show, :preview]

  def index
    articles = @klass.published
                     .ordered
                     .by_locale(I18n.locale)
                     .includes(:published_topics,
                               cover_placement: :file)

    @pagy, @articles = pagy(articles, items: 10)

    @topics = Dummy::Blog::Topic.published
                                .by_locale(I18n.locale)
                                .with_published_articles
                                .ordered
                                .limit(20)
  end

  def show
    force_correct_path(url_for(@article))
  end

  private
    def find_article
      @article = @klass.published_or_admin(account_signed_in?)
                       .by_locale(I18n.locale)
                       .includes(cover_placement: :file)
                       .friendly.find(params[:id])

      set_meta_variables(@article)
    end
end
