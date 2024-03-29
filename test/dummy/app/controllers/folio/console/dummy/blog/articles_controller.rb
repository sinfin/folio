# frozen_string_literal: true

class Folio::Console::Dummy::Blog::ArticlesController < Folio::Console::BaseController
  folio_console_controller_for "Dummy::Blog::Article"

  private
    def article_params
      params.require(:dummy_blog_article)
            .permit(*(@klass.column_names - ["id"]),
                    *atoms_strong_params,
                    *file_placements_strong_params,
                    topic_article_links_attributes: %w[id _destroy position dummy_blog_topic_id])
    end

    def index_filters
      {
        by_locale: Dummy::Blog.available_locales,
        by_published: [true, false],
        by_topic_slug: {
          klass: "Dummy::Blog::Topic",
          order_scope: :ordered,
          slug: true,
        },
      }
    end

    def folio_console_collection_includes
      [:topics, cover_placement: :file]
    end

    def folio_console_record_includes
      []
    end
end
