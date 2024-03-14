# frozen_string_literal: true

class Dummy::Searches::AutocompleteComponent < ApplicationComponent
  def initialize(search:)
    @search = search
  end
end
