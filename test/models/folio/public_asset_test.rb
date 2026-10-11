# frozen_string_literal: true

require "test_helper"

class Folio::PublicAssetTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  setup do
    @site = create_site(force: true)
  end

  teardown do
    Folio::PublicAsset.where(site: @site).destroy_all
    @site.destroy!
  end

  test "stores arbitrary original bytes outside the media library" do
    file_count = Folio::File.count
    asset = create(:folio_public_asset, site: @site)
    assert_equal file_count, Folio::File.count
    assert_equal File.binread(Folio::Engine.root.join("test/fixtures/files/public_asset.json")), asset.reload.data
    assert_match(%r{\Apublic_assets/#{asset.token}/}, asset.s3_key)
    assert_equal "application/json", asset.file_mime_type
  end

  test "replacement preserves the public URL and removes the previous object after commit" do
    asset = create(:folio_public_asset, site: @site)
    old_key = asset.s3_key
    url = asset.public_url
    replacement = Rack::Test::UploadedFile.new(Folio::Engine.root.join("test/fixtures/folio/test.gif"), "image/gif")
    bytes = replacement.read
    asset.update!(file: replacement)
    assert_equal url, asset.reload.public_url
    assert_equal bytes, asset.data
    assert_equal "image/gif", asset.file_mime_type
    assert_not_equal old_key, asset.s3_key
    assert_raises(Errno::ENOENT) { Folio::PublicAssets::Storage.new.read(key: old_key) }
  end

  test "destroying an asset removes its original object" do
    asset = create(:folio_public_asset, site: @site)
    key = asset.s3_key
    asset.destroy!
    assert_raises(Errno::ENOENT) { Folio::PublicAssets::Storage.new.read(key:) }
  end

  test "S3 handling uploads original bytes and MIME to an independent key" do
    client = Aws::S3::Client.new(stub_responses: true, region: "eu-west-1",
                               credentials: Aws::Credentials.new("test-key", "test-secret"))
    storage = Folio::PublicAssets::Storage.new
    original = Rack::Test::UploadedFile.new(Folio::Engine.root.join("test/fixtures/files/public_asset.json"), "application/json")
    original.read
    Folio::S3::Client.stub(:build_client, client) do
      Folio::S3::Client.stub(:bucket_name, "test-bucket") do
        storage.stub(:use_local_file_system?, false) do
          Folio::PublicAssets::Storage.stub(:root_path, "project/test/public_assets") do
            key = storage.write(upload: original, token: SecureRandom.uuid,
                                file_name: "original.json", mime_type: "application/json")
            request = client.api_requests.last[:params]
            assert_equal "test-bucket", request[:bucket]
            assert_match(%r{\Aproject/test/public_assets/}, request[:key])
            assert_equal "application/json", request[:content_type]
            assert_equal File.binread(original.path), request[:body].read
            client.stub_responses(:get_object, body: "original")
            assert_equal "original", storage.read(key:)
            storage.delete(key:)
            assert_equal :delete_object, client.api_requests.last[:operation_name]
          end
        end
      end
    end
  end

  test "requires an original file for a new record" do
    asset = Folio::PublicAsset.new(site: @site)
    assert_not asset.save
    assert asset.errors.added?(:file, :blank)
  end

  test "failed replacement transaction keeps the original object and discards the new one" do
    asset = create(:folio_public_asset, site: @site)
    original = asset.data
    new_key = nil
    Folio::PublicAsset.transaction(requires_new: true) do
      asset.update!(file: Rack::Test::UploadedFile.new(Folio::Engine.root.join("test/fixtures/folio/test.gif"), "image/gif"))
      new_key = asset.s3_key
      raise ActiveRecord::Rollback
    end
    assert_equal original, asset.reload.data
    assert_raises(Errno::ENOENT) { Folio::PublicAssets::Storage.new.read(key: new_key) }
  end
end
