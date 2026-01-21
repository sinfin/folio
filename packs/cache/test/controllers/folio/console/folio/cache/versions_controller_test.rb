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
end
