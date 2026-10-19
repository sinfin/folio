# frozen_string_literal: true

require "test_helper"

class Folio::PublicAssetsControllerTest < ActionDispatch::IntegrationTest
  test "serves arbitrary supported file types without transforming original bytes" do
    site = create_and_host_site
    samples = [
      ["png", "image/png", Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jg2cAAAAASUVORK5CYII=").b],
      ["svg", "image/svg+xml", '<svg xmlns="http://www.w3.org/2000/svg"><circle r="2"/></svg>'],
      ["html", "text/html", "<!doctype html><p>Public HTML</p>"],
      ["js", "text/javascript", "window.publicAsset = true"],
      ["pdf", "application/pdf", "%PDF-1.4\nOriginal bytes"],
      ["custom", "application/octet-stream", "original\x00\x01bytes"],
    ]
    samples.each do |extension, mime, content|
      original = Tempfile.new(["asset", ".#{extension}"])
      original.binmode
      original.write(content)
      original.rewind
      asset = Folio::PublicAsset.create!(site:,
                                            file: Rack::Test::UploadedFile.new(original.path, mime))

      get asset.public_url
      assert_response :ok
      assert_equal content, response.body
      assert_equal mime, response.media_type
      assert_equal "*", response.headers["Access-Control-Allow-Origin"]
      assert_equal "sandbox allow-scripts", response.headers["Content-Security-Policy"]
    end
  end

  test "keeps native audio and video previews on their original origin" do
    site = create_and_host_site
    samples = [
      ["sample.wav", "audio/x-wav", Base64.decode64("UklGRiYAAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQIAAACAgA==").b],
      ["sample.mp4", "video/mp4", File.binread(Folio::Engine.root.join("test/fixtures/folio/blank.mp4"))],
    ]
    samples.each do |filename, mime, content|
      asset = Folio::PublicAsset.create!(site:, file: upload(content, filename:, mime:))

      get asset.public_url
      assert_response :ok
      assert_equal mime, response.media_type
      assert_equal "*", response.headers["Access-Control-Allow-Origin"]
      assert_nil response.headers["Content-Security-Policy"]

      get asset.public_url, headers: { "If-None-Match" => response.headers["ETag"] }
      assert_response :not_modified
      assert_nil response.headers["Content-Security-Policy"]
    end
  end

  test "serves original bytes and revalidates replacement on a stable URL" do
    site = create_and_host_site
    asset = Folio::PublicAsset.create!(site:, file: upload('{"first":true}'))
    stable_url = asset.public_url

    get stable_url
    assert_response :ok
    assert_equal '{"first":true}', response.body
    assert_equal "application/json", response.media_type
    assert_includes response.headers["Cache-Control"], "must-revalidate"
    old_etag = response.headers["ETag"]

    get stable_url, headers: { "If-None-Match" => old_etag }
    assert_response :not_modified

    asset.update!(file: upload('{"second":true}'))
    assert_equal stable_url, asset.public_url
    get stable_url, headers: { "If-None-Match" => old_etag }
    assert_response :ok
    assert_equal '{"second":true}', response.body
    assert_not_equal old_etag, response.headers["ETag"]

    other = Folio::PublicAsset.create!(site:, file: upload("{}"))
    assert_not_equal stable_url, other.public_url
  end

  test "missing public asset returns not found" do
    create_and_host_site
    assert_raises(ActiveRecord::RecordNotFound) do
      get Folio::Engine.routes.url_helpers.public_asset_path(token: SecureRandom.uuid)
    end
  end

  test "disabled feature does not serve files" do
    site = create_and_host_site
    asset = create(:folio_public_asset, site:)
    with_config(folio_public_assets_enabled: false) do
      get asset.public_url
      assert_response :not_found
    end
  end

  private
    def upload(content, filename: "sample.json", mime: "application/json")
      file = Tempfile.new(["public-asset", File.extname(filename)])
      file.binmode
      file.write(content)
      file.rewind
      Rack::Test::UploadedFile.new(file.path, mime, original_filename: filename)
    end
end
