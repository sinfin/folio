# frozen_string_literal: true

class Folio::Console::FilePlacements::MultiPickerFields::PlacementComponent < Folio::Console::ApplicationComponent
  def initialize(g:)
    @g = g
  end

  private
    def data
      stimulus_controller("f-c-file-placements-multi-picker-fields-placement",
                          values: {
                            file_id: @g.object.file_id || "",
                          })
    end
end
