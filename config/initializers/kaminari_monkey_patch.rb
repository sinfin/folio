# frozen_string_literal: true

# Please see https://github.com/amatsuda/kaminari/pull/322 for an explanation.
# This fixes an issue when using Kaminari with engines/main_app.

Rails.application.config.to_prepare do
  Kaminari::Helpers::Tag.class_eval do
    def page_url_for(page)
      params = params_for(page)
      params[:only_path] = true
      @template.url_for params
    rescue ActionController::UrlGenerationError
      @template.main_app.url_for params
    end
  end
end
