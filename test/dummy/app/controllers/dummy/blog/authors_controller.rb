# frozen_string_literal: true

class Dummy::Blog::AuthorsController < Dummy::Blog::BaseController
  def show
    folio_run_unless_cached(["blog/authors#index", params[:page], params[Dummy::Blog::TOPICS_PARAM]] + cache_key_base) do
      @author = Dummy::Blog::Author.published_or_preview_token(params[Folio::Publishable::PREVIEW_PARAM_NAME])
                                   .by_locale(I18n.locale)
                                   .by_site(Folio::Current.site)
                                   .friendly.find(params[:id])

      return if force_correct_path(url_for(@author))

      set_meta_variables(@author)
      add_breadcrumb_on_rails @author.to_label

      published_articles_count = @author.published_articles.count
      @published_articles_count = t(".published_articles_count", count: published_articles_count)

      @hero_links = if @author.social_links.present?
        @author.social_links.map do |key, value|
          { label: key, href: value }
        end
      end
    end
  end
end
