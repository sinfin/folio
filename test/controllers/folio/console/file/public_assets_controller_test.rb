# frozen_string_literal: true

require "test_helper"

class Folio::Console::File::PublicAssetsControllerTest < Folio::Console::BaseControllerTest
  test "public assets use the file library index and detail with a stable URL" do
    asset = create(:folio_file_public_asset)
    get url_for([:console, Folio::File::PublicAsset])
    assert_response :success
    assert_select "turbo-frame[id=#{Folio::File::PublicAsset.console_turbo_frame_id}]"

    get url_for([:console, asset])
    assert_response :success
    assert_select ".f-c-ui-clipboard[data-clipboard-text=?]", asset.public_url
    assert_select "a[href=?]", asset.public_url
  end

  test "disabled feature does not allow console access" do
    with_config(folio_public_assets_enabled: false) do
      get url_for([:console, Folio::File::PublicAsset])
      assert_response :not_found
    end
  end
end
