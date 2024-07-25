# frozen_string_literal: true

class Dummy::Blog::ArticlesController < Dummy::Blog::BaseController
  def index
    folio_run_unless_cached(["blog/articles#index", params[:page], params[:t]] + cache_key_base) do
      @page = blog_articles_index_page
      set_meta_variables(@page)

      @atom_options = { page: @page }
    end
  end

  def show
    @hide_breadcrumbs = true

    folio_run_unless_cached(["blog/articles#show", params[:id]] + cache_key_base) do
      @article = Dummy::Blog::Article.published_or_preview_token(params[Folio::Publishable::PREVIEW_PARAM_NAME])
                                     .by_locale(I18n.locale)
                                     .by_site(Folio::Current.site)
                                     .friendly.find(params[:id])

      unless force_correct_path(url_for(@article))
        add_breadcrumb_on_rails @article.title
        set_meta_variables(@article)

        @page = Dummy::Page::Blog::Articles::Index.instance(site: Folio::Current.site, fail_on_missing: true)

        articles = Dummy::Blog::Article.published
                                       .ordered
                                       .where.not(id: @article.id)
                                       .by_locale(I18n.locale)
                                       .by_site(Folio::Current.site)
                                       .includes(Dummy::Blog.article_includes)

        @articles = articles.limit(3)
      end
    end
  end
end
