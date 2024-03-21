# frozen_string_literal: true

class Dummy::Searches::ResultsListComponent < ApplicationComponent
  THUMB_SIZE = "150x100#"

  def initialize(data:)
    @data = data
  end

  def shows
    render if @data.present? && @data[:records].present?
  end
end
