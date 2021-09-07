# frozen_string_literal: true

class Dummy::Searches::ResultsListCell < ApplicationCell
  def show
    render if model.present?
  end
end
