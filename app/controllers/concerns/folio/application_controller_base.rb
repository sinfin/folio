# frozen_string_literal: true

module Folio
  module ApplicationControllerBase
    extend ActiveSupport::Concern

    included do
      protect_from_forgery with: :exception

      layout 'folio/application'

      helper_method :current_admin
      helper_method :nested_page_path
      helper_method :page_roots

      before_action do
        @site = Site.current
        I18n.locale = params[:locale] || @site.locale
      end
    end

    def current_admin
      current_account
    end

    def default_url_options(options = {})
      { locale: I18n.locale }.merge options
    end

    def nested_page_path(page_or_parts, add_parents: false, params: {})
      if add_parents
        nested_page_path_with_parents(page_or_parts, params: params)
      else
        if page_or_parts.respond_to?(:slug)
          main_app.page_path page_or_parts.slug, params: params
        elsif page_or_parts.is_a?(Array)
          main_app.page_path page_or_parts.map(&:slug).join('/'), params: params
        else
          fail 'Unknown nested_page_path target'
        end
      end
    end

    private

      def nested_page_path_with_parents(page, params: {})
        path = [page]
        while page.parent
          path.unshift page.parent.translate
          page = page.parent
        end
        main_app.page_path path.map(&:slug).join('/'), params: params
      end

      def page_roots
        @page_roots ||= @site.nodes.with_locale(I18n.locale).roots.ordered
      end
  end
end
