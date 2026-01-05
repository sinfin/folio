# frozen_string_literal: true

class Folio::FileList::LoaderComponent < ApplicationComponent
  bem_class_name :light

  def initialize(data: nil, light: true)
    @data = data
    @light = light
  end
end
