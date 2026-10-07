# frozen_string_literal: true

require "test_helper"

class Folio::Console::Api::File::PublicAssetsControllerTest < Folio::Console::BaseControllerTest
  test "file API lists, updates and deletes public assets" do
    asset = create(:folio_file_public_asset)
    get url_for([:console, :api, Folio::File::PublicAsset, format: :json])
    assert_response :success

    patch url_for([:console, :api, asset, format: :json]), params: { file: { attributes: { headline: "Updated asset" } } }
    assert_response :success
    assert_equal "Updated asset", asset.reload.headline

    assert_difference("Folio::File.count", -1) do
      delete url_for([:console, :api, asset, format: :json])
      assert_response :success
    end
  end

  test "disabled feature does not allow file API access" do
    with_config(folio_public_assets_enabled: false) do
      get url_for([:console, :api, Folio::File::PublicAsset, format: :json])
      assert_response :not_found
    end
  end
end
