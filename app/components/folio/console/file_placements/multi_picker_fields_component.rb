# frozen_string_literal: true

class Folio::Console::FilePlacements::MultiPickerFieldsComponent < Folio::Console::ApplicationComponent
  def initialize(f:, placement_klass:)
    @f = f
    @placement_klass = placement_klass

    @placement_key = placement_klass.reflect_on_association(:placement).options[:inverse_of]
    @file_klass = placement_klass.reflect_on_association(:file).options[:class_name].constantize
  end

  private
    def data
      stimulus_controller("f-c-file-placements-multi-picker-fields",
                          values: {
                            iframe_src:,
                          })
    end

    def iframe_src
      url_for([:index_for_picker, :console, @file_klass])
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
