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
end
