# frozen_string_literal: true

require "test_helper"

class Folio::Console::Files::Show::ThumbnailsComponentTest < Folio::Console::ComponentTest
  test "render" do
    with_controller_class(Folio::Console::File::ImagesController) do
      with_request_url "/console/file/images" do
        file = create(:folio_file_image)

        render_inline(Folio::Console::Files::Show::ThumbnailsComponent.new(file:))

        assert_selector(".f-c-files-show-thumbnails")
      end
    end
  end

  test "render shows a chevron on the all-thumbnails disclosure" do
    with_controller_class(Folio::Console::File::ImagesController) do
      with_request_url "/console/file/images" do
        file = create(:folio_file_image)
        file.update!(thumbnail_sizes: { "80x80#" => { url: "https://example.com/80x80.jpg" } })

        render_inline(Folio::Console::Files::Show::ThumbnailsComponent.new(file:))

        assert_selector("details.f-c-files-show-thumbnails__all summary .f-c-files-show-thumbnails__all-summary-chevron svg")
        assert_selector("details.f-c-files-show-thumbnails__all .f-c-files-show-thumbnails__all-heading",
                        text: "Verze a velikosti",
                        visible: :all)
      end
    end
  end

  test "render uses configured group labels and ordering for the current site" do
    with_controller_class(Folio::Console::File::ImagesController) do
      with_request_url "/console/file/images" do
        file = create(:folio_file_image)
        site = file.site
        expected_site = site
        file.update!(thumbnail_sizes: {
          "100x100#" => { url: "https://example.com/100x100.jpg" },
          "200x100#" => { url: "https://example.com/200x100.jpg" },
        })
        groups_proc = lambda do |groups:, site:|
          assert_equal expected_site, site
          assert_equal %w[1×1 2×1], groups.fetch("main_crop").pluck("ratio_label")

          groups.merge(
            "main_crop" => groups.fetch("main_crop").reverse,
            "crop" => groups["crop"].reverse.map do |group|
              group.merge("label" => group["ratio"] == "2:1" ? "Hero" : "Card")
            end
          )
        end

        Folio::Current.stub(:site, site) do
          Rails.application.config.stub(:folio_console_files_thumbnail_groups_proc, -> { groups_proc }) do
            render_inline(Folio::Console::Files::Show::ThumbnailsComponent.new(file:))
          end
        end

        document = Nokogiri::HTML(rendered_content)
        ratio_labels = document.css(".f-c-files-show-thumbnails-ratio__label").map(&:text)
        list_ratio_labels = document.css(".f-c-files-show-thumbnails-crop-edit__ratio-label").map(&:text)
        labels = document.css(".f-c-files-show-thumbnails-crop-edit__label").map(&:text)

        assert_equal %w[2×1 1×1], ratio_labels
        assert_equal %w[2×1 1×1], list_ratio_labels
        assert_equal %w[Hero Card], labels
      end
    end
  end

  test "render uses main families for tiles and detailed ratios for the disclosure" do
    with_controller_class(Folio::Console::File::ImagesController) do
      with_request_url "/console/file/images" do
        file = create(:folio_file_image)
        file.update!(thumbnail_sizes: {
          "100x100#" => { url: "https://example.com/100x100.jpg" },
          "200x120#" => { url: "https://example.com/200x120.jpg" },
          "400x250#" => { url: "https://example.com/400x250.jpg" },
          "800x450#" => { url: "https://example.com/800x450.jpg" },
        })

        render_inline(Folio::Console::Files::Show::ThumbnailsComponent.new(file:))

        assert_selector(".f-c-files-show-thumbnails__tiles .f-c-files-show-thumbnails-ratio__label",
                        text: "1×1",
                        count: 1)
        assert_selector(".f-c-files-show-thumbnails__tiles .f-c-files-show-thumbnails-ratio__label",
                        text: "16×9",
                        count: 1)
        assert_selector(".f-c-files-show-thumbnails__tiles .f-c-files-show-thumbnails-ratio",
                        count: 2)
        assert_selector(".f-c-files-show-thumbnails__all-list .f-c-files-show-thumbnails-crop-edit__ratio-label",
                        count: 4,
                        visible: :all)
      end
    end
  end
end
