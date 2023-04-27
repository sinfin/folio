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

  def hint_for(fp)
    t(".hint.#{fp.object.class.reflections["file"].class_name}", default: nil)
  end

  def btn_label
    if %w[image document].exclude?(klass.human_type)
      t(".add_file")
    end
  end

  def klass
    @klass ||= model[:file_type].constantize
  end

  def content_cell_name
    case klass.human_type
    when "audio", "video"
      "folio/player"
    when "image", "document"
      "folio/console/file/picker/thumb"
    else
      fail "Unknown human_type #{klass.human_type}"
    end
  end
end
