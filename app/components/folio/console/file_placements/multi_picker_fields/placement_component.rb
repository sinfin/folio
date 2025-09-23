# frozen_string_literal: true

class Folio::Console::FilePlacements::MultiPickerFields::PlacementComponent < Folio::Console::ApplicationComponent
  bem_class_name :non_unique_file_id

  def initialize(g:, non_unique_file_id: false)
    @g = g
    @non_unique_file_id = non_unique_file_id
  end

  private
    def data
      stimulus_controller("f-c-file-placements-multi-picker-fields-placement",
                          values: {
                            state:,
                            embed: embed?,
                          },
                          action: {
                            "f-c-file-placements-multi-picker-fields-placement:highlight" => "onHighlight",
                          })
    end

    def embed_data_with_defaults
      @embed_data_with_defaults ||= @g.object.folio_embed_data || {}
    end

    def embed?
      return @embed if defined?(@embed)
      @embed = embed_data_with_defaults["active"] == true
    end

    def state
      return "filled" if embed?
      @g.object.file_id.blank? ? "loading" : "filled"
    end
end
