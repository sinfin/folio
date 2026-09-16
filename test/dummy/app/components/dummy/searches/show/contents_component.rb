# frozen_string_literal: true

class Dummy::Searches::Show::ContentsComponent < ApplicationComponent
  def initialize(search:)
    @search = search
  end
end
