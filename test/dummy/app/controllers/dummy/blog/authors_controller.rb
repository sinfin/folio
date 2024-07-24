# frozen_string_literal: true

class Dummy::Blog::AuthorsController < Dummy::Blog::BaseController
  def show
    folio_run_unless_cached(["blog/authors#index", params[:page]] + cache_key_base) do
      @author = Dummy::Blog::Author.published_or_preview_token(params[Folio::Publishable::PREVIEW_PARAM_NAME])
                                   .by_locale(I18n.locale)
                                   .by_site(Folio::Current.site)
                                   .friendly.find(params[:id])

      return if force_correct_path(url_for(@author))

      set_meta_variables(@author)

      articles = @author.published_articles
                        .by_site(Folio::Current.site)
                        .ordered
                        .includes(Dummy::Blog.article_includes)

      set_pagy_and_articles_from_scope(articles)

      add_breadcrumb_on_rails @author.to_label
    end
  end
end
