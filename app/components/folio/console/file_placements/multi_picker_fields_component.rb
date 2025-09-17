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
                            "f-c-files-batch-bar:addToPicker" => "onBatchBarAddToPicker",
                            "f-nested-fields:add" => "onCountChange",
                            "f-nested-fields:destroyed" => "onCountChange",
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
          data: stimulus_action(click: "onAddEmbedClick"),
        }
      ]
    end
end
