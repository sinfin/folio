# frozen_string_literal: true

class Folio::Console::Files::MediaSourceSelectComponent < Folio::Console::ApplicationComponent
  def initialize(file:)
    @file = file
  end

  def data
    stimulus_controller("f-c-files-media-source-select")
  end
end
