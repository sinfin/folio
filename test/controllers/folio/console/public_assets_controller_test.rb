# frozen_string_literal: true

require "test_helper"

class Folio::Console::PublicAssetsControllerTest < Folio::Console::BaseControllerTest
  test "simplified list offers a public URL for each asset without media filters or warnings" do
    assets = create_list(:folio_public_asset, 2, site: @site)
    with_config(folio_files_require_attribution: true, folio_files_require_description: true) do
      I18n.with_locale(:cs) do
        get console_public_assets_path
        assert_response :success
        assert_select "label", text: /Mé veřejné soubory/
        assert_select "[name=by_used], [name=by_tag_id], .f-file-list-file__part--warning, .f-c-files-batch-bar", count: 0
        assets.each do |asset|
          assert_select ".f-c-catalogue__cell--actions .f-c-ui-clipboard[data-clipboard-text=?] button", asset.public_url
          assert_select "a[title=?][href=?]", I18n.t("folio.console.actions.preview"), asset.public_url
          assert_select "a[title=?][href=?][download=?]", I18n.t("folio.console.actions.download_original"), asset.public_url, asset.file_name
        end
      end
    end
  end

  test "upload and replacement preserve the public URL and only show the original file field" do
    assert_difference("Folio::PublicAsset.count", 1) do
      post console_public_assets_path, params: { public_asset: { file: upload("public_asset.json"), author: "Ignored", tag_list: "Ignored" } }
      assert_response :redirect
    end
    asset = Folio::PublicAsset.order(:id).last
    url = asset.public_url
    assert_equal @superadmin.id, asset.created_by_folio_user_id
    get edit_console_public_asset_path(asset)
    assert_response :success
    assert_select "input[type=file][name=?]", "public_asset[file]"
    assert_select "input[name*=author], input[name*=slug], input[name*=headline], textarea[name*=public_asset], .f-c-files-show__collapsibles", count: 0
    patch console_public_asset_path(asset), params: { public_asset: { file: upload("test.gif") } }
    assert_response :redirect
    assert_equal url, asset.reload.public_url
    assert_equal "image/gif", asset.file_mime_type
    delete console_public_asset_path(asset)
    assert_response :redirect
    assert_not Folio::PublicAsset.exists?(asset.id)
  end

  test "my assets filter hides files uploaded by other users" do
    mine = create(:folio_public_asset, site: @site, created_by_folio_user: @superadmin)
    other = create(:folio_public_asset, site: @site)
    get console_public_assets_path(created_by_current_user: "1")
    assert_response :success
    assert_select ".f-c-ui-clipboard[data-clipboard-text=?]", mine.public_url
    assert_select ".f-c-ui-clipboard[data-clipboard-text=?]", other.public_url, count: 0
  end

  test "manager cannot change an asset from another site" do
    user = create(:folio_user)
    user.set_roles_for(site: @site, roles: [:manager])
    sign_in user
    other = create(:folio_public_asset, site: create_site(force: true))
    assert_raises(ActiveRecord::RecordNotFound) do
      get edit_console_public_asset_path(other)
    end
  end

  test "disabled feature does not allow console access" do
    with_config(folio_public_assets_enabled: false) do
      get console_public_assets_path
      assert_response :not_found
    end
  end

  private
    def upload(name)
      path = name == "test.gif" ? "test/fixtures/folio/test.gif" : "test/fixtures/files/#{name}"
      Rack::Test::UploadedFile.new(Folio::Engine.root.join(path))
    end
end
