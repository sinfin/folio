# frozen_string_literal: true

require "test_helper"

class Folio::S3::ClientTest < ActiveSupport::TestCase
  class ClassWithS3Client
    include Folio::S3::Client # it is mixin
  end

  setup do
    @instance = ClassWithS3Client.new
  end

  test "recognize when to use local file system instead S3" do
    Dragonfly.app.stub(:datastore, Dragonfly::FileDataStore.new) do
      assert @instance.send(:use_local_file_system?)
      assert_equal "/tmp/folio_tmp_user_photo_uploads/foo", @instance.send(:test_aware_s3_path, "foo")
    end

    @instance = ClassWithS3Client.new
    Dragonfly.app.stub(:datastore, Dragonfly::S3DataStore.new) do
      assert_not @instance.send(:use_local_file_system?)
      assert_equal "test_files/foo", @instance.send(:test_aware_s3_path, "foo")
    end
  end

  test "if storing to S3, prefix path with test_files for TEST env" do
    assert Rails.env.test? # surprise, surprise !
    s3_path = "soubory/1.png"

    @instance.stub(:use_local_file_system?, true) do
      url = @instance.test_aware_presign_url(s3_path:)
      assert_equal "https://dummy-s3-bucket.com/#{s3_path}", url
    end

    @instance.stub(:use_local_file_system?, false) do
      url = @instance.test_aware_presign_url(s3_path:)
      expected = s3_url_without_path + "test_files/" + s3_path
      assert url.starts_with?(expected), "#{url} should start with #{expected}"
    end

    @instance.stub(:use_local_file_system?, false) do
      url =  Rails.env.stub(:test?, false) do
        @instance.test_aware_presign_url(s3_path:)
      end
      expected = s3_url_without_path + s3_path
      assert url.starts_with?(expected), "#{url} should start with #{expected}"
    end
  end

  test "test_aware_s3_delete" do
    s3_path = "test_path/empty.pdf"
    file_path = Folio::Engine.root.join("test", "fixtures", "folio", "empty.pdf")
    FileUtils.cp(file_path, "/tmp/folio_tmp_user_photo_uploads/#{s3_path}")
    @instance.test_aware_s3_delete(s3_path:)
    assert_not File.exist?("/tmp/folio_tmp_user_photo_uploads/#{s3_path}"), "File should be deleted"
  ensure
    File.delete("/tmp/folio_tmp_user_photo_uploads/#{s3_path}") if File.exist?("/tmp/folio_tmp_user_photo_uploads/#{s3_path}")
  end

  test "test_aware_s3_upload" do
    s3_path = "test_path/empty.pdf"
    file_path = Folio::Engine.root.join("test", "fixtures", "folio", "empty.pdf")
    @instance.test_aware_s3_upload(s3_path:, file: File.open(file_path))
    assert File.exist?("/tmp/folio_tmp_user_photo_uploads/#{s3_path}"), "File should exist"
  ensure
    File.delete("/tmp/folio_tmp_user_photo_uploads/#{s3_path}") if File.exist?("/tmp/folio_tmp_user_photo_uploads/#{s3_path}")
  end

  def s3_url_without_path
    "#{ENV["S3_SCHEME"]}://#{ENV["S3_BUCKET_NAME"]}.s3.#{ENV["S3_REGION"]}.amazonaws.com/"
  end
end
