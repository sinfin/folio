# frozen_string_literal: true

class Folio::FileList::FileComponent < Folio::ApplicationComponent
  def initialize(file:, template: false)
    @file = file
    @template = template
  end

  def data
    stimulus_controller("f-file-list-file")
  end
end
