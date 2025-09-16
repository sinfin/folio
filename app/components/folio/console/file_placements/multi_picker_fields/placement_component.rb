# frozen_string_literal: true

class Folio::Console::FilePlacements::MultiPickerFields::PlacementComponent < Folio::Console::ApplicationComponent
  def initialize(g:)
    @g = g
  end

  private
    def data
      stimulus_controller("f-c-file-placements-multi-picker-fields-placement",
                          values: {
                            state: @g.object.file_id.blank? ? "loading" : "filled",
                          })
    end
end
