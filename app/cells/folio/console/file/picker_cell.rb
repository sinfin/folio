# frozen_string_literal: true

class Folio::Console::File::PickerCell < Folio::ConsoleCell
  def data
    {
      "controller" => "f-c-file-picker",
      "f-c-file-picker-file-type-value" => model[:file_type],
      "f-c-file-picker-has-file-value" => file_placement && file_placement.file ? "true" : "false",
    }
  end

  def file_placement
    @file_placement ||= model[:f].object.send(model[:placement_key])
  end
end
