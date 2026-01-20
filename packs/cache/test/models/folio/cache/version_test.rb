# frozen_string_literal: true

require "test_helper"

class Folio::Cache::VersionTest < ActiveSupport::TestCase
  test "validates key presence and uniqueness per site" do
    version = build(:folio_cache_version, key: nil)
    assert_not version.valid?
    assert_includes version.errors.details[:key].map { |e| e[:error] }, :blank

    site = create_site
    create(:folio_cache_version, key: "unique-key", site: site)

    duplicate = build(:folio_cache_version, key: "unique-key", site: site)
    assert_not duplicate.valid?
    assert_includes duplicate.errors.details[:key].map { |e| e[:error] }, :taken
  end

  test "allows same key for different sites" do
    site1 = create_site
    site2 = create_site(force: true)

    create(:folio_cache_version, key: "same-key", site: site1)
    version2 = build(:folio_cache_version, key: "same-key", site: site2)

    assert version2.valid?
    assert version2.save
  end

  test "cache_key_for returns correct format" do
    site = create_and_host_site
    version = create(:folio_cache_version, site:, key: "published")

    version_key = Folio::Cache::Version.cache_key_for(keys: ["published"], site:)
    assert version_key.present?
    assert_includes version_key, "published"
    assert_includes version_key, version.updated_at.to_i.to_s
  end

  test "cache_key_for handles empty keys" do
    site = create_and_host_site

    version_key = Folio::Cache::Version.cache_key_for(keys: [], site:)
    assert_nil version_key
  end

  test "cache_key_for handles multiple keys" do
    site = create_and_host_site
    v1 = create(:folio_cache_version, site:, key: "published")
    v2 = create(:folio_cache_version, site:, key: "navigation")

    version_key = Folio::Cache::Version.cache_key_for(keys: ["published", "navigation"], site:)
    assert version_key.present?
    assert_includes version_key, "published"
    assert_includes version_key, "navigation"
    assert_includes version_key, "/"
    assert_includes version_key, v1.updated_at.to_i.to_s
    assert_includes version_key, v2.updated_at.to_i.to_s
  end

  test "cache_key_for handles missing versions" do
    site = create_and_host_site
    create(:folio_cache_version, site:, key: "published")

    # Request a key that doesn't exist
    version_key = Folio::Cache::Version.cache_key_for(keys: ["published", "missing"], site:)
    assert version_key.present?
    assert_includes version_key, "published"
    assert_includes version_key, "missing-0" # Missing version gets 0 timestamp
  end

  test "cache_key_for returns nil when no site" do
    version_key = Folio::Cache::Version.cache_key_for(keys: ["published"], site: nil)
    assert_nil version_key
  end

  test "versions_hash_for_site returns hash of key to timestamp" do
    site = create_and_host_site
    v1 = create(:folio_cache_version, site:, key: "published")
    v2 = create(:folio_cache_version, site:, key: "navigation")

    hash = Folio::Cache::Version.versions_hash_for_site(site)
    assert_equal 2, hash.size
    assert_equal v1.updated_at, hash["published"]
    assert_equal v2.updated_at, hash["navigation"]
  end

  test "versions_hash_for_site returns empty hash for nil site" do
    hash = Folio::Cache::Version.versions_hash_for_site(nil)
    assert_equal({}, hash)
  end

  test "versions_hash_for_site only returns versions for specified site" do
    site1 = create_and_host_site
    site2 = create_site(force: true)

    create(:folio_cache_version, site: site1, key: "site1-key")
    create(:folio_cache_version, site: site2, key: "site2-key")

    hash1 = Folio::Cache::Version.versions_hash_for_site(site1)
    hash2 = Folio::Cache::Version.versions_hash_for_site(site2)

    assert_equal 1, hash1.size
    assert_equal 1, hash2.size
    assert hash1.key?("site1-key")
    assert hash2.key?("site2-key")
    assert_not hash1.key?("site2-key")
    assert_not hash2.key?("site1-key")
  end

  test "cache_key_for uses Folio::Current.cache_versions_hash when available" do
    site = create_and_host_site
    v1 = create(:folio_cache_version, site:, key: "published")
    v2 = create(:folio_cache_version, site:, key: "navigation")

    # Pre-load versions into Current
    cached_hash = Folio::Current.cache_versions_hash
    assert cached_hash.present?
    assert_equal v1.updated_at, cached_hash["published"]
    assert_equal v2.updated_at, cached_hash["navigation"]

    # Verify cache_key_for uses the cached hash
    version_key = Folio::Cache::Version.cache_key_for(keys: ["published", "navigation"], site:)
    assert version_key.present?
    assert_includes version_key, "published"
    assert_includes version_key, "navigation"
    assert_includes version_key, v1.updated_at.to_i.to_s
    assert_includes version_key, v2.updated_at.to_i.to_s

    # Verify subsequent call to cache_versions_hash returns same cached hash
    assert_same cached_hash, Folio::Current.cache_versions_hash
  end
end
