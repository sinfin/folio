# frozen_string_literal: true

class Dummy::Blog::Articles::ShowCell < ApplicationCell
  include Folio::AtomsHelper

  THUMB_SIZE = Dummy::Ui::ArticleCardCell::THUMB_SIZE
end
