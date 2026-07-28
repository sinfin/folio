# frozen_string_literal: true

class Folio::PlayerComponent < ApplicationComponent
  def initialize(file:, file_hash: nil, show_form_controls: false)
    @file = file
    @file_hash = file_hash
    @show_form_controls = show_form_controls
  end

  def data
    stimulus_controller("f-player",
                        values: {
                          file_json: (@file_hash || serializer.new(@file).serializable_hash[:data]).to_json,
                          show_form_controls: @show_form_controls,
                        })
  end

  def serializer
    if @show_form_controls
      Folio::Console::FileSerializer
    else
      Folio::FileSerializer
    end
  end
end
