# frozen_string_literal: true

require "test_helper"

class Folio::Console::Folio::Cache::VersionsControllerTest < Folio::Console::BaseControllerTest
  test "index" do
    get url_for([:console, Folio::Cache::Version])

    assert_response :success

    create(:folio_cache_version)

    get url_for([:console, Folio::Cache::Version])

    assert_response :success
  end

  test "destroy" do
    model = create(:folio_cache_version)

    delete url_for([:console, model])

    assert_redirected_to url_for([:console, Folio::Cache::Version])
    assert_not(Folio::Cache::Version.exists?(id: model.id))
  end

  test "invalidate" do
    model = create(:folio_cache_version)
    original_updated_at = model.updated_at

    travel 1.minute do
      post url_for([:invalidate, :console, model])

      assert_redirected_to url_for([:console, Folio::Cache::Version])
      assert_not_nil flash[:notice]

      model.reload
      assert model.updated_at > original_updated_at
    end
  end

  test "invalidate_all" do
    version1 = create(:folio_cache_version, site: @site)
    version2 = create(:folio_cache_version, site: @site)
    other_site = create_site(force: true)
    other_site_version = create(:folio_cache_version, site: other_site)

    original_updated_at1 = version1.updated_at
    original_updated_at2 = version2.updated_at
    original_updated_at_other = other_site_version.updated_at

    travel 1.minute do
      post url_for([:invalidate_all, :console, Folio::Cache::Version])

      assert_redirected_to url_for([:console, Folio::Cache::Version])
      assert_not_nil flash[:notice]

      version1.reload
      version2.reload
      other_site_version.reload

      assert version1.updated_at > original_updated_at1
      assert version2.updated_at > original_updated_at2
      assert_equal original_updated_at_other.to_i, other_site_version.updated_at.to_i
    end
  end

  test "clear_rails_cache" do
    test_key = "cache_versions_test_#{SecureRandom.hex}"
    Rails.cache.write(test_key, "test_value")
    assert_equal "test_value", Rails.cache.read(test_key)

    post url_for([:clear_rails_cache, :console, Folio::Cache::Version])

    assert_redirected_to url_for([:console, Folio::Cache::Version])
    assert_not_nil flash[:notice]

    # Verify cache was cleared by checking the key is gone
    assert_nil Rails.cache.read(test_key), "Cache should be cleared after clear_rails_cache action"
  end
end
