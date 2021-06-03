# frozen_string_literal: true

class Folio::Console::Dummy::Blog::CategoriesController < Folio::Console::BaseController
  folio_console_controller_for "Dummy::Blog::Category"

  private
    def category_params
      params.require(:dummy_blog_category)
            .permit(*(@klass.column_names - ["id"]),
                    *file_placements_strong_params)
    end

    def index_filters
      {
        by_locale: Dummy::Blog.available_locales,
        by_published: [true, false],
        by_featured: [true, false],
      }
    end

    def folio_console_collection_includes
      []
    end

    def folio_console_record_includes
      []
    end
end
