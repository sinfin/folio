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
        render(@page.original.class.view_name) && (return)
      end
    end

    private

      def find_page
        path = params[:path].split('/')

        @page = page_roots
        @page = @page.published unless admin_preview?
        @page = @page.friendly.find path.shift
        add_breadcrumb @page.title, nested_page_path(@page, add_parents: true)

        path.each do |p|
          @page = @page.children.with_locale(I18n.locale)
          @page = @page.published unless admin_preview?
          @page = @page.friendly.find p
          add_breadcrumb @page.title, nested_page_path(@page, add_parents: true)
        end

        # # If an old id or a numeric id was used to find the record, then
        # # the request path will not match the post_path, and we should do
        # # a 301 redirect that uses the current friendly id.
        # if request.path != page_path(@page)
        #   return redirect_to @page, status: :moved_permanently
        # end
        #
      end

      def add_meta
        @title = @page.title
        @description = @page.perex
        @og_title = @title
        @og_description = @description
      end

      def admin_preview?
        current_admin.present?
      end
  end
end
