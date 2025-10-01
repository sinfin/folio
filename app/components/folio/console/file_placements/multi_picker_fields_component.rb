# frozen_string_literal: true

class Folio::Console::FilePlacements::MultiPickerFieldsComponent < Folio::Console::ApplicationComponent
  def initialize(f:, placement_klass:)
    @f = f
    @placement_klass = placement_klass

    @placement_key = placement_klass.reflect_on_association(:placement).options[:inverse_of]
    @file_klass = placement_klass.reflect_on_association(:file).options[:class_name].constantize
  end

  private
    def before_render
      @turbo_frame_id = @file_klass.console_turbo_frame_id(picker: true)
      @turbo_frame_src = url_for([:index_for_picker, :console, @file_klass])
    end

    def data
      stimulus_controller("f-c-file-placements-multi-picker-fields",
                          values: {
                            empty: @f.object.send(@placement_key).blank?,
                          },
                          action: {
                            "f-c-file-placements-multi-picker-fields:addToPicker" => "onAddToPicker",
                            "f-nested-fields:added" => "onAdded",
                            "f-nested-fields:destroyed" => "onDestroyed",
                          })
    end

    def tabs
      [
        {
          label: t(".select/#{@file_klass.human_type}", default: t(".select/default")),
          active: true,
        },
        {
          icon: :plus_circle,
          label: t(".add_embed"),
          dont_bind_tab_toggle: true,
          text_color: "green",
          data: stimulus_controller("f-c-file-placements-multi-picker-fields-add-embed",
                                    inline: true,
                                    action: { click: "onAddEmbedClick" })
        }
      ]
    end

    def non_unique_file_ids
      @non_unique_file_ids ||= begin
        h = {}

        @f.object.send(@placement_key).each do |placement|
          next if placement.marked_for_destruction?
          next if placement.file_id.blank?

          h[placement.file_id] ||= 0
          h[placement.file_id] += 1
        end

        h.select { |_, v| v > 1 }.keys
      end
    end

    def placement_component(g)
      component_klass = Folio::Console::FilePlacements::MultiPickerFields::PlacementComponent
      non_unique_file_id = non_unique_file_ids.include?(g.object.file_id)

      render(component_klass.new(g:, non_unique_file_id:, placement_key: @placement_key))
    end
end
