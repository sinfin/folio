# frozen_string_literal: true

require "test_helper"

class Folio::Console::Files::UsageConstraintsComponentTest < Folio::Console::ComponentTest
  def test_render_shows_site_max_usage_overrides
    with_config(folio_shared_files_between_sites: true) do
      site_with_override = create(:dummy_site, title: "Site with override")
      site_without_override = create(:dummy_site, title: "Site without override")
      media_source = create(:folio_media_source, max_usage_count: 10)
      media_source.media_source_site_links.create!(site: site_with_override, max_usage_count: 3)
      media_source.media_source_site_links.create!(site: site_without_override)
      file = create(:folio_file_image,
                    site: site_with_override,
                    attribution_source: media_source.title,
                    media_source: nil)

      with_controller_class(Folio::Console::File::ImagesController) do
        with_request_url "/console/file/images" do
          render_inline(Folio::Console::Files::UsageConstraintsComponent.new(file:))

          assert_selector(".f-c-files-usage-constraints__sites", text: "Site with override (3)")
          assert_selector(".f-c-files-usage-constraints__sites", text: "Site without override")
          assert_no_selector(".f-c-files-usage-constraints__sites", text: "Site without override (10)")
        end
      end
    end
  end
end
