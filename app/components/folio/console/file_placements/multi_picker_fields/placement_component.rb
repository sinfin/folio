# frozen_string_literal: true

class Folio::Console::FilePlacements::MultiPickerFields::PlacementComponent < Folio::Console::ApplicationComponent
  bem_class_name :non_unique_file_id

  def initialize(g:, non_unique_file_id: false, placement_key:, embed_input_options: nil, placement_attributes: nil)
    @g = g
    @non_unique_file_id = non_unique_file_id
    @placement_key = placement_key
    @embed_input_options = embed_input_options
    @placement_attributes = placement_attributes || Folio::Console::FilePlacements::MultiPickerFieldsComponent::DEFAULT_PLACEMENT_ATTRIBUTES
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

    def placement_attribute_input_options(attr)
      case attr
      when :description
        { autosize: true, input_html: { rows: 1, data: stimulus_target("description") } }
      when :alt
        { input_html: { data: stimulus_target("alt") } }
      when :title
        { as: :string }
      when :folio_embed_data
        nil
      else
        {}
      end
    end

    def placement_attribute_wrapper_data(attr)
      case attr
      when :alt
        stimulus_target("altWrap")
      when :folio_embed_data
        stimulus_target("embedFieldsWrap")
      else
        nil
      end
    end
end
