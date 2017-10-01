# frozen_string_literal: true

require_dependency 'folio/application_controller'

module Folio
  class PagesController < BaseController
    before_action :find_page

    def show; end

    private

      def find_page
        @page = @roots.published.friendly.find params[:id]
        add_breadcrumb @page.title, page_url(@page)

        if params[:child_id]
          @page = @page.children.published.friendly.find params[:child_id]
          add_breadcrumb @page.title, page_url(@page.parent, child_id: @page)
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
