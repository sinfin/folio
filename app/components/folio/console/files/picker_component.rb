# frozen_string_literal: true

class Folio::Console::Files::PickerComponent < Folio::Console::ApplicationComponent
  def initialize(f:, placement_key:, file_klass:, hint: nil, darker: false, required: false)
    @f = f
    @placement_key = placement_key
    @file_klass = file_klass
    @hint = hint
    @darker = darker
    @required = required
  end

  def data
    stimulus_controller("f-c-files-picker",
                        values: {
                          file_type: @file_klass.to_s,
                          state:,
                        },
                        action: {
                          "f-c-files-index-modal:selectedFile" => "onModalSelectedFile"
                        })
  end

  def file_placement
    @file_placement ||= @f.object.send(@placement_key) || @f.object.send("build_#{@placement_key}")
  end

  def hint_for(fp)
    @hint.presence || t(".hint.#{fp.object.class.reflections["file"].class_name}", default: nil)
  end

  def content_component
    case @file_klass.human_type
    when "audio", "video"
      Folio::PlayerComponent.new(file: file_placement.file, show_form_controls: true)
    when "image"
      Folio::Console::Files::Picker::ImageComponent.new(file: file_placement.file)
    when "document"
      Folio::Console::Files::Picker::DocumentComponent.new(file: file_placement.file)
    else
      fail "Unknown human_type #{@file_klass.human_type}"
    end
  end

  def state
    if file_placement && file_placement.file
      if file_placement.marked_for_destruction?
        "marked-for-destruction"
      else
        "filled"
      end
    else
      "empty"
    end
  end
end
