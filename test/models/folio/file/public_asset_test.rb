# frozen_string_literal: true

require "test_helper"

class Folio::File::PublicAssetTest < ActiveSupport::TestCase
  test "public asset is stored in the existing file library without image processing" do
    upload = Rack::Test::UploadedFile.new(Folio::Engine.root.join("test/fixtures/folio/test.gif"), "image/gif")
    original = upload.read

    assert_difference("Folio::File.count", 1) do
      asset = Folio::File::PublicAsset.create!(site: create(:dummy_site), file: upload)
      asset.process!
      assert_equal original, Folio::File.find(asset.id).file.data
      assert_empty asset.thumbnail_sizes
    end
  end

  test "file sharing preserves an existing public URL and its site on replacement" do
    site = create(:dummy_site)
    asset = Rails.application.config.stub(:folio_shared_files_between_sites, false) do
      create(:folio_file_public_asset, site:)
    end
    url = asset.public_url

    Rails.application.config.stub(:folio_shared_files_between_sites, true) do
      asset.update!(file: Rack::Test::UploadedFile.new(Folio::Engine.root.join("test/fixtures/files/public_asset.json"), "application/json"))
    end

    assert_equal site.id, asset.reload.site_id
    assert_equal url, asset.public_url
  end

  test "file replacement and metadata changes preserve the public URL" do
    asset = create(:folio_file_public_asset)
    url = asset.public_url
    token = asset.public_asset_token
    asset.update!(file: Rack::Test::UploadedFile.new(Folio::Engine.root.join("test/fixtures/files/public_asset.json"), "application/json"),
                  headline: "Updated", slug: "updated")

    assert_equal url, asset.reload.public_url
    assert_equal token, asset.public_asset_token
    assert_not_equal url, create(:folio_file_public_asset).public_url
  end
end
