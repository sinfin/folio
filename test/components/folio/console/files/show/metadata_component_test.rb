# frozen_string_literal: true

require "test_helper"

class Folio::Console::Files::Show::MetadataComponentTest < Folio::Console::ComponentTest
  def test_render
    with_controller_class(Folio::Console::File::ImagesController) do
      with_request_url "/console/file/images" do
        image_path = Folio::Engine.root.join("test/fixtures/folio/metadata_test_images/IPTC-PhotometadataRef-Std2021.1.jpg")
        image = nil

        Rails.application.config.stub(:folio_image_metadata_extraction_enabled, true) do
          image = create(:folio_file_image, file: File.open(image_path))
        end

        render_inline(Folio::Console::Files::Show::MetadataComponent.new(file: image))
        assert_selector(".f-c-files-show-metadata", text: "The description aka caption (ref2021.1)")
      end
    end
  end
end
