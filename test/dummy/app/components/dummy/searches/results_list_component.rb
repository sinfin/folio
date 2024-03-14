# frozen_string_literal: true

class Dummy::Searches::ResultsListComponent < ApplicationComponent
  THUMB_SIZE = "150x100#"

  def initialize(search)
    @search = search
  end

  def shows
    render if @search.present?
  end
end
