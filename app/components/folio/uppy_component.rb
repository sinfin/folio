# frozen_string_literal: true

class Folio::UppyComponent < Folio::ApplicationComponent
  bem_class_name :inline

  def initialize(file_type: "Folio::File::Image", inline: false)
    @file_type = file_type
    @inline = inline
  end

  def data
    stimulus_controller("f-uppy",
                        values: {
                          file_type: @file_type,
                          inline: @inline,
                        })
  end
end
