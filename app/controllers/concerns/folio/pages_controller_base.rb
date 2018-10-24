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

        pages = page_roots
        pages = pages.published unless admin_preview?
        @page = pages.friendly.find path.shift
        add_breadcrumb @page.title, nested_page_path(@page, add_parents: true)

        path.each do |path_part|
          children = @page.children.with_locale(I18n.locale)
          children = children.published unless admin_preview?
          @page = children.friendly.find path_part
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
  end
end
