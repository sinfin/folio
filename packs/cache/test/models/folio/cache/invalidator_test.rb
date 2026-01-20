# frozen_string_literal: true

require "test_helper"

class Folio::Cache::InvalidatorTest < ActiveSupport::TestCase
  test "invalidate! updates timestamps for matching versions" do
    site = create_site
    version = create(:folio_cache_version, site:, key: "published")
    original_updated_at = version.updated_at

    travel 1.second do
      Folio::Cache::Invalidator.invalidate!(site_id: site.id, keys: ["published"])
    end

    assert version.reload.updated_at > original_updated_at
  end

  test "invalidate! updates multiple keys at once" do
    site = create_site
    v1 = create(:folio_cache_version, site:, key: "published")
    v2 = create(:folio_cache_version, site:, key: "navigation")
    v3 = create(:folio_cache_version, site:, key: "other")

    travel 1.second do
      Folio::Cache::Invalidator.invalidate!(site_id: site.id, keys: ["published", "navigation"])
    end

    assert v1.reload.updated_at > v1.created_at
    assert v2.reload.updated_at > v2.created_at
    assert_equal v3.reload.updated_at, v3.created_at
  end

  test "invalidate! does nothing with empty keys" do
    site = create_site
    version = create(:folio_cache_version, site:, key: "published")
    original_updated_at = version.updated_at

    Folio::Cache::Invalidator.invalidate!(site_id: site.id, keys: [])

    assert_equal original_updated_at, version.reload.updated_at
  end

  test "invalidate! only affects specified site" do
    site1 = create_site
    site2 = create_site(force: true)
    v1 = create(:folio_cache_version, site: site1, key: "published")
    v2 = create(:folio_cache_version, site: site2, key: "published")

    travel 1.second do
      Folio::Cache::Invalidator.invalidate!(site_id: site1.id, keys: ["published"])
    end

    assert v1.reload.updated_at > v1.created_at
    assert_equal v2.reload.updated_at, v2.created_at
  end

  test "invalidate! sets expires_at when lambda configured" do
    site = create_site
    expires_at = 1.day.from_now

    Folio::Cache.configure do
      Folio::Cache.expires_at_for_key = ->(key:, site:) do
        expires_at if key == "published"
      end

      Folio::Cache::Invalidator.invalidate!(site_id: site.id, keys: ["published"])

      version = Folio::Cache::Version.find_by(site:, key: "published")
      assert_equal expires_at.to_i, version.expires_at.to_i
    end
  end

  test "invalidate! updates expires_at when lambda returns new value" do
    site = create_site
    version = create(:folio_cache_version, site:, key: "published", expires_at: 1.day.from_now)
    new_expires_at = 2.days.from_now

    Folio::Cache.configure do
      Folio::Cache.expires_at_for_key = ->(key:, site:) do
        new_expires_at if key == "published"
      end

      Folio::Cache::Invalidator.invalidate!(site_id: site.id, keys: ["published"])

      assert_equal new_expires_at.to_i, version.reload.expires_at.to_i
    end
  end

  test "invalidate! creates missing versions with upsert_all" do
    site = create_site

    Folio::Cache::Invalidator.invalidate!(site_id: site.id, keys: ["new_key"])

    version = Folio::Cache::Version.find_by(site:, key: "new_key")
    assert version.present?
    assert version.created_at.present?
    assert version.updated_at.present?
  end
end
