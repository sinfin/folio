# frozen_string_literal: true

class Folio::Console::Files::Batch::FormComponent < Folio::Console::ApplicationComponent
  def initialize(file_klass:)
    @file_klass = file_klass
  end

  def data
    stimulus_controller("f-c-files-batch-form")
  end
end
