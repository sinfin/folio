# frozen_string_literal: true

class Dummy::Atom::Blog::Articles::IndexComponent < ApplicationComponent
  include Pagy::Backend

  def initialize(atom:, atom_options: {})
    @atom = atom
    @atom_options = atom_options
  end

  def before_render
    @page = @atom_options[:page] || Dummy::Page::Blog::Articles::Index.instance(site: current_site, fail_on_missing: true)

    articles = Dummy::Blog::Article.published
                                   .ordered
                                   .by_locale(locale)
                                   .by_site(current_site)
                                   .includes(Dummy::Blog.article_includes)


    @topics = Dummy::Blog::Topic.published
                                .by_locale(locale)
                                .by_site(current_site)
                                .with_published_articles
                                .ordered
                                .limit(20)

    @pagy, @articles = pagy(articles, items: Dummy::Blog::ARTICLE_PAGY_ITEMS)
  end
end
