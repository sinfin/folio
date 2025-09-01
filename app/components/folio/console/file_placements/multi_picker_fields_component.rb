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
      stimulus_controller("f-c-file-placements-multi-picker-fields")
    end
end
