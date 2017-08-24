# frozen_string_literal: true

module Folio
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception

    before_action do
      @site = Folio::Site.first
      @roots = @site.nodes.where(locale: I18n.locale).roots
  
      I18n.locale = @site.locale unless params[:locale]
    end
  end
end
