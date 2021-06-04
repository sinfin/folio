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

    if params[:q].present?
      articles = articles.by_query(params[:q])
    end

    @pagy, @articles = pagy(articles, items: 10)
  end

  def show
    if @article.published?
      force_correct_path(url_for(@article))
    else
      redirect_to action: :preview
    end
  end

  def preview
    if @article.published?
      redirect_to action: :show
    else
      render :show
    end
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
