# frozen_string_literal: true

require "test_helper"

class Folio::Console::Files::ArtworkFormComponentTest < Folio::Console::ComponentTest
  def test_render_picker_without_artwork
    audio = create(:folio_file_audio)

    with_controller_class(Folio::Console::File::AudiosController) do
      with_request_url "/console/file/audios/#{audio.id}" do
        render_inline(Folio::Console::Files::ArtworkFormComponent.new(file: audio))

        assert_selector(".f-c-files-artwork-form")
        assert_selector(".f-c-files-picker")
        assert_no_selector(".f-c-files-artwork-form__validation-box")
      end
    end
  end

  def test_render_warnings_for_placed_artwork_missing_metadata
    audio = create(:folio_file_audio)
    image = create(:folio_file_image, author: nil, attribution_source: nil, description: nil)
    audio.create_artwork_cover_placement!(file: image)

    Rails.application.config.stub(:folio_files_require_attribution, true) do
      with_controller_class(Folio::Console::File::AudiosController) do
        with_request_url "/console/file/audios/#{audio.id}" do
          render_inline(Folio::Console::Files::ArtworkFormComponent.new(file: audio))

          assert_selector(".f-c-files-artwork-form__validation-box")
        end
      end
    end
  end
end
