# frozen_string_literal: true

class Dummy::Blog::Articles::ShowHeaderComponent < ApplicationComponent
  COVER_SIZE = "1184x565#"
  AUTHOR_AVATAR_SIZE = "24x24#"

  def initialize(article:, breadcrumbs: nil)
    @article = article
    @breadcrumbs = breadcrumbs
  end

  def photo_author
    @photo_author ||= @article.cover_placement.try(:file).try(:author)
  end

  def hero_component
    render(Dummy::Ui::HeroComponent.new(title: @article.title,
                                        perex: @article.perex,
                                        cover: @article.cover_placement,
                                        date: @article.published_at_with_fallback.to_date,
                                        authors: @article.authors.includes(cover_placement: :file).map do |author|
                                          {
                                            cover: author.cover,
                                            name: author.full_name,
                                            href: url_for(author),
                                          }
                                        end,
                                        breadcrumbs: @breadcrumbs))
  end
end
