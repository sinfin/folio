# frozen_string_literal: true

class Dummy::Searches::ResultsListComponent < ApplicationComponent
  def show
    render if @search.present?
  end
end
