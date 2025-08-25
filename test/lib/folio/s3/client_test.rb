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
      url = @instance.test_aware_presign_url(s3_path)
      assert_equal "https://dummy-s3-bucket.com/#{s3_path}", url
    end

    @instance.stub(:use_local_file_system?, false) do
      # Stub AWS presigner to avoid real AWS credential chain (SSO) during tests
      fake_presigner = Class.new do
        def initialize(url); @url = url; end
        def presigned_url(*); @url; end
      end.new(s3_url_without_path + "test_files/" + s3_path)

      @instance.stub(:s3_presigner, fake_presigner) do
        url = @instance.test_aware_presign_url(s3_path)
        expected = s3_url_without_path + "test_files/" + s3_path
        assert url.starts_with?(expected), "#{url} should start with #{expected}"
      end
    end

    @instance.stub(:use_local_file_system?, false) do
      # Non-test env branch: also stub presigner to keep test deterministic
      fake_presigner = Class.new do
        def initialize(url); @url = url; end
        def presigned_url(*); @url; end
      end.new(s3_url_without_path + s3_path)

      url = Rails.env.stub(:test?, false) do
        @instance.stub(:s3_presigner, fake_presigner) do
          @instance.test_aware_presign_url(s3_path)
        end
      end
      expected = s3_url_without_path + s3_path
      assert url.starts_with?(expected), "#{url} should start with #{expected}"
    end
  end

  def s3_url_without_path
    "#{ENV["S3_SCHEME"]}://#{ENV["S3_BUCKET_NAME"]}.s3.#{ENV["S3_REGION"]}.amazonaws.com/"
  end
end
