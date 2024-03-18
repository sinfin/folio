# frozen_string_literal: true

class Dummy::Blog::Articles::CardComponent < ApplicationComponent
  COVER_SIZE = "80x80#"
  MAIN_COVER_SIZE = "360x220#"

  def initialize(article:, size: :md)
    @article = article
    @size = size
  end
end
