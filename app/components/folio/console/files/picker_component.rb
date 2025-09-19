# frozen_string_literal: true

class Folio::Console::Files::PickerComponent < Folio::Console::ApplicationComponent
  def initialize(f:,
                 file_klass:,
                 file_placement: nil,
                 placement_key: nil,
                 in_place_inputs: nil,
                 hint: nil,
                 darker: false,
                 size: "default",
                 required: false)
    @f = f
    @placement_key = placement_key
    @file_klass = file_klass
    @hint = hint
    @darker = darker
    @required = required
    @file_placement = file_placement
    @size = size
    @in_place_inputs = in_place_inputs

    if @file_placement
      @as_file_placement = true
    else
      @as_file_placement = false

      if @placement_key
        @file_placement = @f.object.send(@placement_key) || @f.object.send("build_#{@placement_key}")
      else
        raise ArgumentError, "placement_key must be provided when file_placement is nil"
      end
    end
  end

  def data
    stimulus_controller("f-c-files-picker",
                        values: {
                          file_type: @file_klass.to_s,
                          serialized_file_json: "",
                          as_file_placement: @as_file_placement,
                          state:,
                        },
                        action: {
                          "f-c-files-picker:fillWithFile" => "onFillWithFile",
                          "f-c-files-index-modal:selectedFile" => "onModalSelectedFile"
                        })
  end

  def hint_for(fp)
    @hint.presence || t(".hint.#{fp.object.class.reflections["file"].class_name}", default: nil)
  end

  def content_component
    case @file_klass.human_type
    when "audio", "video"
      Folio::PlayerComponent.new(file: @file_placement.file, show_form_controls: true)
    when "image"
      Folio::Console::Files::Picker::ImageComponent.new(file: @file_placement.file)
    when "document"
      Folio::Console::Files::Picker::DocumentComponent.new(file: @file_placement.file)
    else
      fail "Unknown human_type #{@file_klass.human_type}"
    end
  end

  def state
    if @file_placement && @file_placement.file
      if @file_placement.marked_for_destruction?
        "marked-for-destruction"
      else
        "filled"
      end
    else
      "empty"
    end
  end

  def placement_aware_fields_for(&block)
    if @as_file_placement
      yield @f
    else
      @f.simple_fields_for @placement_key, @file_placement, &block
    end
  end
end
