# frozen_string_literal: true

require "test_helper"

class Folio::Api::S3ControllerTest < Folio::BaseControllerTest
  class FakeS3Client
    attr_reader :calls

    def initialize
      @calls = []
    end

    def create_multipart_upload(**kwargs)
      @calls << [:create_multipart_upload, kwargs]
      OpenStruct.new(upload_id: "upload-123")
    end

    def complete_multipart_upload(**kwargs)
      @calls << [:complete_multipart_upload, kwargs]
      OpenStruct.new(location: "https://example.com/file.mp4")
    end

    def abort_multipart_upload(**kwargs)
      @calls << [:abort_multipart_upload, kwargs]
      OpenStruct.new
    end
  end

  class FakeS3Presigner
    attr_reader :calls

    def initialize
      @calls = []
    end

    def presigned_url(method_name, **kwargs)
      @calls << [method_name, kwargs]
      "https://example.com/presigned-part"
    end
  end

  [Folio::File::Document, Folio::File::Image, Folio::PrivateAttachment].each do |klass|
    test "#{klass} - before" do
      # #before returns settings for S3 file upload
      post before_folio_api_s3_path, params: { file_name: "Intricate fílě name.jpg" }
      assert_response :success

      json = response.parsed_body
      assert json["s3_url"]
      assert json["s3_path"]
      assert_equal "intricate-file-name.jpg", json["file_name"]
    end

    test "#{klass} - after" do
      # #after => load back file from S3 and process it

      # nonexisting file
      assert_enqueued_jobs(0) do
        post after_folio_api_s3_path, params: { s3_path: "foo", type: klass.to_s, existing_id: nil, message_bus_client_id: "foo" }
        assert_response 422
      end

      test_path = "#{Folio::S3::Client::LOCAL_TEST_PATH}/test-#{klass.model_name.singular}.gif"
      FileUtils.mkdir_p(File.dirname(test_path))
      FileUtils.cp(Folio::Engine.root.join("test/fixtures/folio/test.gif"), test_path)

      # file exists
      assert_difference("#{klass}.count", 1) do
        perform_enqueued_jobs do
          post after_folio_api_s3_path, params: { s3_path: "test-#{klass.model_name.singular}.gif", type: klass.to_s, existing_id: nil, message_bus_client_id: "foo" }
          assert_response(:ok)
        end
      end
    end

    test "#{klass} - after with existing id" do
      file = create(klass.model_name.singular, file_name: "foo.gif")

      assert_enqueued_jobs(0) do
        post after_folio_api_s3_path, params: { s3_path: "foo", type: klass.to_s, existing_id: file.id, message_bus_client_id: "foo" }
        assert_response 422
      end

      test_path = "#{Folio::S3::Client::LOCAL_TEST_PATH}/test-#{klass.model_name.singular}-#{file.id}.gif"
      FileUtils.mkdir_p(File.dirname(test_path))
      FileUtils.cp(Folio::Engine.root.join("test/fixtures/folio/test.gif"), test_path)

      assert_not_equal("test.gif", file.file_name)

      assert_difference("#{klass}.count", 0) do
        perform_enqueued_jobs do
          post after_folio_api_s3_path, params: { s3_path: "test-#{klass.model_name.singular}-#{file.id}.gif", type: klass.to_s, existing_id: file.id, message_bus_client_id: "foo" }
          assert_response(:ok)
        end
      end

      assert_equal("test-#{klass.model_name.singular}-#{file.id}.gif", file.reload.file_name)
    end

    test "#{klass} - unauthorized for no admin" do
      sign_out @superadmin

      post before_folio_api_s3_path, params: { file_name: "Intricate fílě name.jpg" }
      assert_response :unauthorized

      test_path = "#{Folio::S3::Client::LOCAL_TEST_PATH}/test-#{klass.model_name.singular}.gif"
      FileUtils.mkdir_p(File.dirname(test_path))
      FileUtils.cp(Folio::Engine.root.join("test/fixtures/folio/test.gif"), test_path)

      assert_difference("#{klass}.count", 0) do
        perform_enqueued_jobs do
          post after_folio_api_s3_path, params: { s3_path: "test-#{klass.model_name.singular}.gif", type: klass.to_s, existing_id: nil, message_bus_client_id: "foo" }
          assert_response :unauthorized
        end
      end
    end

    test "#{klass} - file_list_file" do
      file = create(klass.model_name.singular)

      get file_list_file_folio_api_s3_path(file_id: file.id,
                                           file_type: file.class.to_s,
                                           format: :json)
      assert_response :success

      json = response.parsed_body
      assert json["data"].include?("f-file-list-file")
    end

    test "#{klass} - file_list_file with wrong file_type" do
      file = create(klass.model_name.singular)

      get file_list_file_folio_api_s3_path(file_id: file.id, file_type: "Folio::File::Wrong", format: :json)
      assert_response 404
    end

    test "#{klass} - file_list_file cancancan" do
      file = create(klass.model_name.singular)
      sign_out @superadmin

      get file_list_file_folio_api_s3_path(file_id: file.id, file_type: file.class.to_s, format: :json)
      assert_response :unauthorized
    end
  end

  test "multipart endpoints are disabled by default" do
    original = Rails.application.config.folio_direct_s3_multipart_upload_enabled
    Rails.application.config.folio_direct_s3_multipart_upload_enabled = false

    post create_multipart_upload_folio_api_s3_path, params: {
      file_name: "Large video.mp4",
      type: "Folio::File::Video",
    }

    assert_response :not_found
  ensure
    Rails.application.config.folio_direct_s3_multipart_upload_enabled = original
  end

  test "create_multipart_upload starts S3 multipart upload when enabled" do
    with_enabled_multipart_upload do |fake_client, _fake_presigner|
      post create_multipart_upload_folio_api_s3_path, params: {
        file_name: "Large video.mp4",
        type: "Folio::File::Video",
      }

      assert_response :success

      json = response.parsed_body
      assert_equal "upload-123", json["uploadId"]
      assert_equal "upload-123", json["upload_id"]
      assert_equal "large-video.mp4", json["file_name"]
      assert json["key"].end_with?("/large-video.mp4")
      assert_equal json["key"], json["s3_path"]

      call_name, kwargs = fake_client.calls.first
      assert_equal :create_multipart_upload, call_name
      assert_equal "dummy_bucket", kwargs[:bucket]
      assert_equal "test_files/#{json["key"]}", kwargs[:key]
    end
  end

  test "sign_part returns presigned upload_part url" do
    with_enabled_multipart_upload do |_fake_client, fake_presigner|
      key = create_multipart_upload_key

      post sign_part_folio_api_s3_path, params: {
        key:,
        uploadId: "upload-123",
        partNumber: 2,
      }

      assert_response :success
      assert_equal "https://example.com/presigned-part", response.parsed_body["url"]

      call_name, kwargs = fake_presigner.calls.first
      assert_equal :upload_part, call_name
      assert_equal "dummy_bucket", kwargs[:bucket]
      assert_equal "test_files/#{key}", kwargs[:key]
      assert_equal "upload-123", kwargs[:upload_id]
      assert_equal 2, kwargs[:part_number]
    end
  end

  test "complete_multipart_upload completes S3 upload" do
    with_enabled_multipart_upload do |fake_client, _fake_presigner|
      key = create_multipart_upload_key
      fake_client.calls.clear

      post complete_multipart_upload_folio_api_s3_path, params: {
        key:,
        uploadId: "upload-123",
        parts: [
          { "PartNumber" => 1, "ETag" => "\"etag-1\"" },
          { "PartNumber" => 2, "ETag" => "\"etag-2\"" },
        ],
      }

      assert_response :success
      assert_equal "https://example.com/file.mp4", response.parsed_body["location"]

      call_name, kwargs = fake_client.calls.first
      assert_equal :complete_multipart_upload, call_name
      assert_equal "dummy_bucket", kwargs[:bucket]
      assert_equal "test_files/#{key}", kwargs[:key]
      assert_equal "upload-123", kwargs[:upload_id]
      assert_equal [
        { part_number: 1, etag: "\"etag-1\"" },
        { part_number: 2, etag: "\"etag-2\"" },
      ], kwargs[:multipart_upload][:parts]
    end
  end

  test "abort_multipart_upload aborts S3 upload" do
    with_enabled_multipart_upload do |fake_client, _fake_presigner|
      key = create_multipart_upload_key
      fake_client.calls.clear

      post abort_multipart_upload_folio_api_s3_path, params: {
        key:,
        uploadId: "upload-123",
      }

      assert_response :success

      call_name, kwargs = fake_client.calls.first
      assert_equal :abort_multipart_upload, call_name
      assert_equal "dummy_bucket", kwargs[:bucket]
      assert_equal "test_files/#{key}", kwargs[:key]
      assert_equal "upload-123", kwargs[:upload_id]
    end
  end

  private
    def create_multipart_upload_key
      post create_multipart_upload_folio_api_s3_path, params: {
        file_name: "Large video.mp4",
        type: "Folio::File::Video",
      }

      assert_response :success

      response.parsed_body["key"]
    end

    def with_enabled_multipart_upload
      original_enabled = Rails.application.config.folio_direct_s3_multipart_upload_enabled
      Rails.application.config.folio_direct_s3_multipart_upload_enabled = true
      original_env = ENV.to_h.slice("S3_BUCKET_NAME", "S3_REGION", "AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY")
      ENV["S3_BUCKET_NAME"] = "dummy_bucket"
      ENV["S3_REGION"] = "eu-central-1"
      ENV["AWS_ACCESS_KEY_ID"] = "access-key-id"
      ENV["AWS_SECRET_ACCESS_KEY"] = "secret-access-key"

      fake_client = FakeS3Client.new
      fake_presigner = FakeS3Presigner.new

      Dragonfly.app.stub(:datastore, Dragonfly::S3DataStore.new) do
        Aws::S3::Client.stub(:new, fake_client) do
          Aws::S3::Presigner.stub(:new, fake_presigner) do
            yield fake_client, fake_presigner
          end
        end
      end
    ensure
      Rails.application.config.folio_direct_s3_multipart_upload_enabled = original_enabled
      original_env.each { |key, value| ENV[key] = value }
      (["S3_BUCKET_NAME", "S3_REGION", "AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY"] - original_env.keys).each do |key|
        ENV.delete(key)
      end
    end
end
