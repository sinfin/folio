# frozen_string_literal: true

module Folio
  module ApplicationControllerBase
    extend ActiveSupport::Concern

    included do
      protect_from_forgery with: :exception

      before_action do
        @site = Site.first

        I18n.locale = params[:locale] || @site.locale
        @roots = @site.nodes.where(locale: I18n.locale).roots.ordered
      end
    end

    def default_url_options(options = {})
      { locale: I18n.locale }.merge options
    end
  end
end
