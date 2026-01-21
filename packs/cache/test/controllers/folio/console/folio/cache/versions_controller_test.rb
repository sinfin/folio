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
end
