# frozen_string_literal: true

class Dummy::Blog::BaseController < ApplicationController
  include Dummy::Blog::SetPagyAndArticlesFromScope

  before_action :add_root_blog_breadcrumb

  private
    def blog_articles_index_page
      @blog_articles_index_page ||= Dummy::Page::Blog::Articles::Index.instance(site: Folio::Current.site,
                                                                                fail_on_missing: true)
    end

    def add_root_blog_breadcrumb
      @hide_breadcrumbs = true
      add_breadcrumb_on_rails blog_articles_index_page.title, dummy_blog_articles_path
    end

    def set_pagy_and_articles_from_scope(scope)
      if params[:page].blank? || !params[:page].match?(/\A\d+\z/) || params[:page].to_i <= 1
        @pagy, @articles = pagy(scope, items: Dummy::Blog::ARTICLE_PAGY_ITEMS + 1)
      else
        @pagy, @articles = pagy(scope.offset(1), items: Dummy::Blog::ARTICLE_PAGY_ITEMS, offset: 1)
      end
    end
end
