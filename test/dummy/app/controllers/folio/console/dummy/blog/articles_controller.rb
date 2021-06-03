# frozen_string_literal: true

class Folio::Console::Dummy::Blog::ArticlesController < Folio::Console::BaseController
  folio_console_controller_for "Dummy::Blog::Article"

  private
    def article_params
      params.require(:dummy_blog_article)
            .permit(*(@klass.column_names - ["id"]),
                    *atoms_strong_params,
                    *file_placements_strong_params,
                    category_ids: [])
    end

    def index_filters
      {
by_locale: Dummy::Blog.available_locales,        by_published: [true, false],
        by_category_id: Dummy::Blog::Category.ordered.map do |cat|
          [cat.to_label, cat.id]
        end,
      }
    end

    def folio_console_collection_includes
      []
    end

    def folio_console_record_includes
      []
    end
end
