# frozen_string_literal: true

class Dummy::Ui::AuthorMedallionComponent < ApplicationComponent
  THUMB_SIZE = {
    s: "20x20#c",
    m: "24x24#c",
  }

  def initialize(name:, href:, cover:, size: :s)
    @name = name
    @href = href
    @cover = cover
    @size = size == :s ? :s : :m
  end
end
