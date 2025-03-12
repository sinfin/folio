# frozen_string_literal: true

class Folio::UppyComponent < Folio::ApplicationComponent
  def initialize(file_type: "Folio::File::Image")
    @file_type = file_type
  end

  def data
    stimulus_controller("f-uppy",
                        values: {
                          file_type: @file_type,
                        })
  end
end
