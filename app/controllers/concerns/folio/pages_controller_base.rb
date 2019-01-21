# frozen_string_literal: true

module Folio
  module PagesControllerBase
    extend ActiveSupport::Concern

    included do
      include UrlHelper

      before_action :find_page, :add_meta
    end

    def show
      if @page.original.class.view_name
        render @page.original.class.view_name
      else
        render 'folio/pages/show'
      end
    end

    private

      def find_page
        path = params[:path].split('/')

        @page = page_roots.published_or_admin(admin_preview?)
                          .friendly
                          .find(path.shift)
        add_breadcrumb @page.title, nested_page_path(@page, add_parents: true)

        path.each do |path_part|
          children = filter_pages_by_locale(@page.children)
          @page = children.published_or_admin(admin_preview?)
                          .friendly
                          .find(path_part)
          add_breadcrumb @page.title, nested_page_path(@page, add_parents: true)
        end

        force_correct_path(nested_page_path(@page, add_parents: true))
      end

      def add_meta
        set_meta_variables(@page)
      end

      def admin_preview?
        current_admin.present?
      end

      def filter_pages_by_locale(pages)
        if ::Rails.application.config.folio_using_traco
          pages
        else
          pages.with_locale(I18n.locale)
        end
      end
  end
end
