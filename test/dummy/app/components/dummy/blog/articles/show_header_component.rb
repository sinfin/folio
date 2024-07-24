# frozen_string_literal: true

class Dummy::Blog::Articles::ShowHeaderComponent < ApplicationComponent
  COVER_SIZE = "1184x565#"
  AUTHOR_AVATAR_SIZE = "24x24#"

  def initialize(article:)
    @article = article
  end

  def photo_author
    @photo_author ||= @article.cover_placement.try(:file).try(:author)
  end
end
