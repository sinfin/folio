# frozen_string_literal: true

require "test_helper"

class Folio::Cache::ModelConcernTest < ActiveSupport::TestCase
  class PageWithCacheKeys < Folio::Page
    private
      def folio_cache_version_keys
        ["published", "navigation"]
      end
  end

  test "includes concern in Folio::ApplicationRecord" do
    assert_includes Folio::ApplicationRecord.ancestors, Folio::Cache::ModelConcern
  end

  test "after_commit calls invalidator with correct keys" do
    site = create_site
    v1 = create(:folio_cache_version, site:, key: "published")
    v2 = create(:folio_cache_version, site:, key: "navigation")
    v3 = create(:folio_cache_version, site:, key: "other")

    original_v1_updated_at = v1.updated_at
    original_v2_updated_at = v2.updated_at
    original_v3_updated_at = v3.updated_at

    travel 1.second do
      PageWithCacheKeys.create!(site:, title: "Test", slug: "test-#{SecureRandom.hex(4)}", locale: site.locale)
    end

    assert v1.reload.updated_at > original_v1_updated_at
    assert v2.reload.updated_at > original_v2_updated_at
    assert_equal original_v3_updated_at, v3.reload.updated_at
  end

  test "does not call invalidator when keys are empty" do
    site = create_site
    version = create(:folio_cache_version, site:, key: "published")
    original_updated_at = version.updated_at

    travel 1.second do
      # Folio::Page doesn't override folio_cache_version_keys, so it returns []
      page = create(:folio_page, site:)
      page.update!(title: "Updated")
    end

    assert_equal original_updated_at, version.reload.updated_at
  end

  test "does not call invalidator when site_id is nil" do
    site = create_site
    version = create(:folio_cache_version, site:, key: "published")

    page = PageWithCacheKeys.create!(site:, title: "Test", slug: "test-#{SecureRandom.hex(4)}", locale: site.locale)
    # Get updated_at after creation (callback already fired)
    updated_at_after_create = version.reload.updated_at

    page.update_column(:site_id, nil)
    page.reload

    # Manually call the method to test the nil site_id check
    page.send(:folio_cache_invalidate_versions!)

    # Version should not be updated again since site_id is nil
    assert_equal updated_at_after_create, version.reload.updated_at
  end
end
