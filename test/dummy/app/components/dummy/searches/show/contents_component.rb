# frozen_string_literal: true

class Dummy::Searches::Show::ContentsComponent < ApplicationComponent
  include Pagy::Frontend

  def initialize(search:)
    @search = search
  end
end
