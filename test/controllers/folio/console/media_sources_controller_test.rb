# frozen_string_literal: true

require "test_helper"

class Folio::Console::MediaSourcesControllerTest < Folio::Console::BaseControllerTest
  test "index shows site max usage overrides" do
    with_config(folio_shared_files_between_sites: true) do
      site_with_override = create(:dummy_site, title: "Site with override")
      site_without_override = create(:dummy_site, title: "Site without override")
      media_source = create(:folio_media_source, max_usage_count: 10)
      media_source.media_source_site_links.create!(site: site_with_override, max_usage_count: 3)
      media_source.media_source_site_links.create!(site: site_without_override)

      get url_for([:console, Folio::MediaSource])

      assert_response :success
      assert_select ".f-c-catalogue__row", text: /Site with override \(3\)/
      assert_select ".f-c-catalogue__row", text: /Site without override/
      assert_no_match "Site without override (10)", response.body
    end
  end
end
