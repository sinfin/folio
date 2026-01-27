# frozen_string_literal: true

require "test_helper"

class Folio::Cache::AbilityOverrideTest < ActiveSupport::TestCase
  test "superadmin can read cache versions" do
    user = create(:folio_user, superadmin: true)
    site = create_site
    version = create(:folio_cache_version, site:, key: "test")

    ability = Folio::Ability.new(user, site)

    assert ability.can?(:read, version)
    assert ability.can?(:index, Folio::Cache::Version)
  end

  test "superadmin can update cache versions" do
    user = create(:folio_user, superadmin: true)
    site = create_site
    version = create(:folio_cache_version, site:, key: "test")

    ability = Folio::Ability.new(user, site)

    assert ability.can?(:update, version)
    assert ability.can?(:edit, version)
  end

  test "superadmin can do_anything on cache versions" do
    user = create(:folio_user, superadmin: true)
    site = create_site
    version = create(:folio_cache_version, site:, key: "test")

    ability = Folio::Ability.new(user, site)

    assert ability.can?(:do_anything, version)
  end

  test "non-superadmin cannot access cache versions" do
    user = create(:folio_user, superadmin: false)
    site = create_site
    version = create(:folio_cache_version, site:, key: "test")

    ability = Folio::Ability.new(user, site)

    assert_not ability.can?(:read, version)
    assert_not ability.can?(:index, Folio::Cache::Version)
    assert_not ability.can?(:update, version)
  end
end
