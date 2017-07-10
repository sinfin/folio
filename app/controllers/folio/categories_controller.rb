# frozen_string_literal: true

require_dependency 'folio/application_controller'

module Folio
  class CategoriesController < BaseController
    before_action :find_page

    def show; end

    private

      def find_page
        @category = Folio::Category.friendly.find params[:id]

        # If an old id or a numeric id was used to find the record, then
        # the request path will not match the post_path, and we should do
        # a 301 redirect that uses the current friendly id.
        if request.path != category_path(@category)
          return redirect_to @category, status: :moved_permanently
        end
      end
  end
end
