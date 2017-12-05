# frozen_string_literal: true

module Folio
  module PagesControllerBsae
    extend ActiveSupport::Concern

    included do
      include UrlHelper

      before_action :find_page
    end

    def show
      if @page.class.view_name
        render(@page.class.view_name) && (return)
      end
    end

    private

      def find_page
        path = params[:path].split('/')

        @page = @roots.published.friendly.find path.shift
        add_breadcrumb @page.title, nested_page_path(@page)

        path.each do |p|
          @page = @page.children.published.friendly.find p
          add_breadcrumb @page.title, nested_page_path(@page)
        end

        # # If an old id or a numeric id was used to find the record, then
        # # the request path will not match the post_path, and we should do
        # # a 301 redirect that uses the current friendly id.
        # if request.path != page_path(@page)
        #   return redirect_to @page, status: :moved_permanently
        # end
        #
      end
  end
end
