# frozen_string_literal: true

require "test_helper"

class Folio::Console::Files::Show::Thumbnails::DetailsComponentTest < Folio::Console::ComponentTest
  test "renders generated versions collapsed by default" do
    with_controller_class(Folio::Console::File::ImagesController) do
      with_request_url "/console/file/images" do
        file = create(:folio_file_image)
        file.update!(thumbnail_sizes: { "100x100#" => { url: "https://example.com/100x100.jpg" } })

        render_inline(Folio::Console::Files::Show::Thumbnails::DetailsComponent.new(file:,
                                                                                     details_id: "thumbnail-details"))

        assert_selector(".f-c-files-show-thumbnails-details#thumbnail-details[hidden]", visible: :all)
        assert_selector(".f-c-files-show-thumbnails-details__all-list", visible: :all)
      end
    end
  end

  test "shows the empty state when no thumbnails exist" do
    with_controller_class(Folio::Console::File::ImagesController) do
      with_request_url "/console/file/images" do
        render_inline(Folio::Console::Files::Show::Thumbnails::DetailsComponent.new(file: create(:folio_file_image),
                                                                                     details_id: "thumbnail-details"))

        assert_selector(".f-c-files-show-thumbnails-details:not([hidden])",
                        text: I18n.t("folio.console.files.show.thumbnails.details_component.no_thumbnails_yet"))
      end
    end
  end
end
