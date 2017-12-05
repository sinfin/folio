# frozen_string_literal: true

module Folio
  module ApplicationControllerBase
    extend ActiveSupport::Concern

    included do
      protect_from_forgery with: :exception

      helper_method :nested_page_path

      before_action do
        @site = Site.first

        I18n.locale = params[:locale] || @site.locale
        @roots = @site.nodes.where(locale: I18n.locale).roots.ordered
      end
    end

    def default_url_options(options = {})
      { locale: I18n.locale }.merge options
    end

    def nested_page_path(page_or_parts, add_parents: false)
      if add_parents
        nested_page_path_with_parents(page_or_parts)
      else
        if page_or_parts.respond_to?(:slug)
          main_app.page_path page_or_parts.slug
        elsif page_or_parts.is_a?(Array)
          main_app.page_path page_or_parts.map(&:slug).join('/')
        else
          fail 'Unknown nested_page_path target'
        end
      end
    end

    private

      def nested_page_path_with_parents(page)
        path = [page]
        while page.parent
          path.unshift page.parent.translate
          page = page.parent
        end
        main_app.page_path path.map(&:slug).join('/')
      end
  end
end
