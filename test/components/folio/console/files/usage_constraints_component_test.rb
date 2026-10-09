# frozen_string_literal: true

require "test_helper"

class Folio::Console::Files::UsageConstraintsComponentTest < Folio::Console::ComponentTest
  def test_media_source_global_max_is_read_only_while_file_sites_remain_editable
    with_config(folio_shared_files_between_sites: true) do
      site = create_and_host_site
      media_source = create(:folio_media_source, site:, max_usage_count: 10)
      file = create(:folio_file_image,
                    site:,
                    attribution_source: media_source.title)
      file.allowed_sites << create(:dummy_site)
      authorize_media_source_editing(site)

      render_component(file)

      assert_no_selector(".f-c-files-usage-constraints__max-usage-count .f-c-ui-in-place-input")
      assert_selector(".f-c-files-usage-constraints__max-usage-count-value", text: "10")
      assert_selector('.f-c-files-usage-constraints__media-source-link[data-turbo-frame="_top"]',
                      text: media_source.title,
                      count: 1)
      assert_selector(".f-c-files-usage-constraints__sites .f-c-ui-in-place-input")
    end
  end

  def test_media_source_sites_are_read_only_while_file_max_remains_editable
    with_config(folio_shared_files_between_sites: true) do
      site = create_and_host_site
      allowed_site = create(:dummy_site, title: "Managed site")
      media_source = create(:folio_media_source, site:, max_usage_count: nil)
      media_source.media_source_site_links.create!(site: allowed_site)
      file = create(:folio_file_image,
                    site:,
                    attribution_source: media_source.title,
                    attribution_max_usage_count: 7)
      authorize_media_source_editing(site)

      render_component(file)

      assert_selector(".f-c-files-usage-constraints__max-usage-count .f-c-ui-in-place-input")
      assert_no_selector(".f-c-files-usage-constraints__sites .f-c-ui-in-place-input")
      assert_selector(".f-c-files-usage-constraints__sites-value", text: "Managed site")
      assert_selector(".f-c-files-usage-constraints__media-source-link", text: media_source.title, count: 1)
    end
  end

  def test_file_fallback_controls_remain_editable_without_media_source_rules
    with_config(folio_shared_files_between_sites: true) do
      site = create_and_host_site
      media_source = create(:folio_media_source, site:, max_usage_count: nil)
      file = create(:folio_file_image,
                    site:,
                    attribution_source: media_source.title,
                    attribution_max_usage_count: 7)
      file.allowed_sites << create(:dummy_site)
      authorize_media_source_editing(site)

      render_component(file)

      assert_selector(".f-c-files-usage-constraints .f-c-ui-in-place-input", count: 2)
      assert_no_selector(".f-c-files-usage-constraints__media-source-link")
    end
  end

  def test_read_only_media_source_value_has_no_link_without_permission
    with_config(folio_shared_files_between_sites: true) do
      site = create_and_host_site
      media_source = create(:folio_media_source, site:, max_usage_count: 10)
      file = create(:folio_file_image,
                    site:,
                    attribution_source: media_source.title)

      render_component(file)

      assert_no_selector(".f-c-files-usage-constraints__max-usage-count .f-c-ui-in-place-input")
      assert_no_selector(".f-c-files-usage-constraints__media-source-link")
      assert_selector(".f-c-files-usage-constraints__media-source-name", text: media_source.title)
    end
  end

  def test_media_source_site_max_overrides_are_shown
    with_config(folio_shared_files_between_sites: true) do
      site = create_and_host_site
      site_with_override = create(:dummy_site, title: "Site with override")
      site_without_override = create(:dummy_site, title: "Site without override")
      media_source = create(:folio_media_source, site:, max_usage_count: 10)
      media_source.media_source_site_links.create!(site: site_with_override, max_usage_count: 3)
      media_source.media_source_site_links.create!(site: site_without_override)
      file = create(:folio_file_image,
                    site:,
                    attribution_source: media_source.title)
      authorize_media_source_editing(site)

      render_component(file)

      assert_selector(".f-c-files-usage-constraints__sites-value", text: "Site with override (3)")
      assert_selector(".f-c-files-usage-constraints__sites-value", text: "Site without override")
      assert_no_selector(".f-c-files-usage-constraints__sites-value", text: "Site without override (10)")
      assert_selector(".f-c-files-usage-constraints__media-source-link", text: media_source.title, count: 1)
    end
  end

  private
    def authorize_media_source_editing(site)
      Folio::Current.site = site
      Folio::Current.user = create(:folio_user, :superadmin)
      Folio::Current.reset_ability!
    end

    def render_component(file)
      Folio::Current.reset_ability! unless Folio::Current.ability

      with_controller_class(Folio::Console::File::ImagesController) do
        with_request_url "/console/file/images" do
          render_inline(Folio::Console::Files::UsageConstraintsComponent.new(file:))
        end
      end
    end
end
