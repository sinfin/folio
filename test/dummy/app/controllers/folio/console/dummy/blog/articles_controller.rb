# frozen_string_literal: true

class Folio::Console::Dummy::Blog::ArticlesController < Folio::Console::BaseController
  folio_console_controller_for "Dummy::Blog::Article"

  private
    def article_params
      params.require(:dummy_blog_article)
            .permit(:title,
                    :slug,
                    :perex,
                    :locale,
                    :meta_title,
                    :meta_description,
                    :featured,
                    :published,
                    :published_at,
                    *atoms_strong_params,
                    *file_placements_strong_params,
                    author_article_links_attributes: %w[id _destroy position dummy_blog_author_id],
                    topic_article_links_attributes: %w[id _destroy position dummy_blog_topic_id])
    end

    def index_filters
      {
        by_locale: Dummy::Blog.available_locales,
        by_published: [true, false],
        by_author_slug: {
          klass: "Dummy::Blog::Author",
          order_scope: :ordered,
          slug: true,
        },
        by_topic_slug: {
          klass: "Dummy::Blog::Topic",
          order_scope: :ordered,
          slug: true,
        },
      }
    end

    def folio_console_collection_includes
      [:authors, :topics, cover_placement: :file]
    end
end
