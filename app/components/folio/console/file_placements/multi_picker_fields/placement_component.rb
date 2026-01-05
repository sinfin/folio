# frozen_string_literal: true

class Folio::Console::FilePlacements::MultiPickerFields::PlacementComponent < Folio::Console::ApplicationComponent
  bem_class_name :non_unique_file_id

  def initialize(g:, non_unique_file_id: false, placement_key:, embed_input_options: nil)
    @g = g
    @non_unique_file_id = non_unique_file_id
    @placement_key = placement_key
    @embed_input_options = embed_input_options
  end

  private
    def data
      stimulus_controller("f-c-file-placements-multi-picker-fields-placement",
                          values: {
                            state:,
                            embed: embed?,
                          },
                          action: {
                            "f-c-files-picker:fileDestroyed" => "onFileDestroyed",
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

    def embed_data_has_errors?
      return @embed_data_has_errors if defined?(@embed_data_has_errors)
      @embed_data_has_errors = @g.object.errors[:folio_embed_data].present?
    end

    def folio_embed_data_input(g)
      opts = {
        as: :embed,
        compact: true
      }

      if @embed_input_options.is_a?(Hash)
        @embed_input_options.each do |key, value|
          opts[key] ||= value
        end
      end

      g.input :folio_embed_data, opts
    end
end
