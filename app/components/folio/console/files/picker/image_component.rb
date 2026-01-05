# frozen_string_literal: true

class Folio::Console::Files::Picker::ImageComponent < Folio::Console::ApplicationComponent
  def initialize(file:)
    @file = file
  end

  def data
    file_json = Folio::Console::FileSerializer.new(@file)
                                              .serializable_hash[:data]
                                              .to_json

    stimulus_controller("f-c-files-picker-image").merge(file: file_json)
  end
end
