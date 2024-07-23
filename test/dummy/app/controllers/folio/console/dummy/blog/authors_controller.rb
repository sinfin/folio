# frozen_string_literal: true

class Folio::Console::Dummy::Blog::AuthorsController < Folio::Console::BaseController
  folio_console_controller_for "Dummy::Blog::Author"

  private
    def author_params
      params.require(:dummy_blog_author)
            .permit(*(@klass.column_names - %w[id site_id]),
                    *file_placements_strong_params)
    end

    def index_filters
      {}
    end

    def folio_console_collection_includes
      []
    end
end
