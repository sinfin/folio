# frozen_string_literal: true

class Dummy::Searches::ShowComponent < ApplicationComponent
  def initialize(search:)
    @search = search
  end
end
