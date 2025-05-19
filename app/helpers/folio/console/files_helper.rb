# frozen_string_literal: true

module Folio::Console::FilesHelper
  def file_picker(f:, placement_key:, file_klass:, hint: nil, darker: false, required: nil)
    component = Folio::Console::Files::PickerComponent.new(f:,
                                                           placement_key:,
                                                           file_klass:,
                                                           hint:,
                                                           darker:,
                                                           required:)

    if is_a?(Cell::ViewModel)
      render_view_component(component)
    else
      render(component)
    end
  end

  def file_picker_for_cover(f, hint: nil, darker: false, required: nil)
    file_picker(f:,
                placement_key: :cover_placement,
                file_klass: Folio::File::Image,
                hint:,
                darker:,
                required:)
  end

  def file_picker_for_og_image(f, hint: nil, required: nil)
    file_picker(f:,
                placement_key: :og_image_placement,
                file_klass: Folio::File::Image,
                hint:,
                required:)
  end

  def file_picker_for_document(f, hint: nil, required: nil)
    file_picker(f:,
                placement_key: :document_placement,
                file_klass: Folio::File::Document,
                hint:,
                required:)
  end

  def file_picker_for_audio_cover(f, hint: nil, required: nil)
    file_picker(f:,
                placement_key: :audio_cover_placement,
                file_klass: Folio::File::Audio,
                hint:,
                required:)
  end

  def file_picker_for_video_cover(f, hint: nil, required: nil)
    file_picker(f:,
                placement_key: :video_cover_placement,
                file_klass: Folio::File::Video,
                hint:,
                required:)
  end
end
