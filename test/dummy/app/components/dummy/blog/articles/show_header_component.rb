# frozen_string_literal: true

class Dummy::Blog::Articles::ShowHeaderComponent < ApplicationComponent
  COVER_SIZE = "1184x565#"
  AUTHOR_AVATAR_SIZE = "24x24#"

  def initialize(article:)
    @article = article
  end

end
