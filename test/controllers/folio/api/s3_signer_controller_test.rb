# frozen_string_literal: true

require "test_helper"

class Folio::Api::S3SignerControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include Folio::Engine.routes.url_helpers

  def setup
    create_and_host_site
    @admin = create(:folio_account)
    sign_in @admin
  end

  [Folio::File::Document, Folio::File::Image, Folio::PrivateAttachment].each do |klass|
    test "#{klass} - s3_before" do
      post s3_before_folio_api_s3_signer_path, params: { file_name: "Intricate fílě name.jpg" }
      assert_response :success

      json = response.parsed_body
      assert json["s3_url"]
      assert json["s3_path"]
      assert_equal "intricate-file-name.jpg", json["file_name"]
    end

    test "#{klass} - s3_after" do
      assert_enqueued_jobs(0) do
        post s3_after_folio_api_s3_signer_path, params: { s3_path: "foo", type: klass.to_s, existing_id: nil }
        assert_response 422
      end

      test_path = "#{Folio::S3Client::TEST_PATH}/test-#{klass.model_name.singular}.gif"
      FileUtils.mkdir_p(File.dirname(test_path))
      FileUtils.cp(Folio::Engine.root.join("test/fixtures/folio/test.gif"), test_path)

      assert_difference("#{klass}.count", 1) do
        perform_enqueued_jobs do
          post s3_after_folio_api_s3_signer_path, params: { s3_path: "test-#{klass.model_name.singular}.gif", type: klass.to_s, existing_id: nil }
          assert_response(:ok)
        end
      end
    end

    test "#{klass} - s3_after with existing id" do
      file = create(klass.model_name.singular, file_name: "foo.gif")

      assert_enqueued_jobs(0) do
        post s3_after_folio_api_s3_signer_path, params: { s3_path: "foo", type: klass.to_s, existing_id: file.id }
        assert_response 422
      end

      test_path = "#{Folio::S3Client::TEST_PATH}/test-#{klass.model_name.singular}-#{file.id}.gif"
      FileUtils.mkdir_p(File.dirname(test_path))
      FileUtils.cp(Folio::Engine.root.join("test/fixtures/folio/test.gif"), test_path)

      assert_not_equal("test.gif", file.file_name)

      assert_difference("#{klass}.count", 0) do
        perform_enqueued_jobs do
          post s3_after_folio_api_s3_signer_path, params: { s3_path: "test-#{klass.model_name.singular}-#{file.id}.gif", type: klass.to_s, existing_id: file.id }
          assert_response(:ok)
        end
      end

      assert_equal("test-#{klass.model_name.singular}-#{file.id}.gif", file.reload.file_name)
    end

    test "#{klass} - unauthorized for no account" do
      sign_out @admin

      post s3_before_folio_api_s3_signer_path, params: { file_name: "Intricate fílě name.jpg" }
      assert_response :unauthorized

      test_path = "#{Folio::S3Client::TEST_PATH}/test-#{klass.model_name.singular}.gif"
      FileUtils.mkdir_p(File.dirname(test_path))
      FileUtils.cp(Folio::Engine.root.join("test/fixtures/folio/test.gif"), test_path)

      assert_difference("#{klass}.count", 0) do
        perform_enqueued_jobs do
          post s3_after_folio_api_s3_signer_path, params: { s3_path: "test-#{klass.model_name.singular}.gif", type: klass.to_s, existing_id: nil }
          assert_response :unauthorized
        end
      end
    end
  end
end
