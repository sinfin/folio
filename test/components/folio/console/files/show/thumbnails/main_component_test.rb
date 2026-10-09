# frozen_string_literal: true

require "test_helper"

class Folio::Console::Files::Show::Thumbnails::MainComponentTest < Folio::Console::ComponentTest
  test "renders crop tiles and a collapsed details control for generated thumbnails" do
    with_controller_class(Folio::Console::File::ImagesController) do
      with_request_url "/console/file/images" do
        file = create(:folio_file_image)
        file.update!(thumbnail_sizes: {
          "100x100#" => { url: "https://example.com/100x100.jpg" },
          "200x100#" => { url: "https://example.com/200x100.jpg" },
        })

        render_inline(Folio::Console::Files::Show::Thumbnails::MainComponent.new(file:,
                                                                                  details_id: "thumbnail-details"))

        assert_selector(".f-c-files-show-thumbnails-main__tiles .f-c-files-show-thumbnails-ratio", count: 2)
        assert_selector("button.f-c-files-show-thumbnails-main__toggle[aria-controls='thumbnail-details'][aria-expanded='false']")
      end
    end
  end

  test "does not render without generated thumbnails" do
    with_controller_class(Folio::Console::File::ImagesController) do
      with_request_url "/console/file/images" do
        render_inline(Folio::Console::Files::Show::Thumbnails::MainComponent.new(file: create(:folio_file_image),
                                                                                  details_id: "thumbnail-details"))

        assert_no_selector(".f-c-files-show-thumbnails-main")
      end
    end
  end
end
