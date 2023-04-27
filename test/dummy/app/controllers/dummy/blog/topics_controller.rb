# frozen_string_literal: true

class Dummy::Blog::TopicsController < ApplicationController
  before_action { @klass = Dummy::Blog::Topic }
  before_action :find_topic, only: [:show, :preview]

  def show
    force_correct_path(url_for(@topic))
  end

  private
    def find_topic
      @topic = @klass.published_or_preview_token(params[Folio::Publishable::PREVIEW_PARAM_NAME])
                     .by_locale(I18n.locale)
                     .friendly.find(params[:id])

      articles = @topic.published_articles
                       .ordered
                       .includes(:published_topics,
                                 cover_placement: :file)

      @pagy, @articles = pagy(articles, items: 20)
    end
end
