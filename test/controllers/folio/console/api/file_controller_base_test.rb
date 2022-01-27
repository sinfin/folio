# frozen_string_literal: true

require "test_helper"

class Folio::Console::Api::FileControllerBaseTest < Folio::Console::BaseControllerTest
  [Folio::Document, Folio::Image].each do |klass|
    test "#{klass} - index" do
      get url_for([:console, :api, klass])
      assert_response :success
    end

    test "#{klass} - s3_before" do
      post url_for([:s3_before, :console, :api, klass]), params: { file_name: "Intricate fílě name.jpg" }
      assert_response :success

      json = response.parsed_body
      assert json["s3_url"]
      assert json["s3_path"]
      assert_equal "intricate-file-name.jpg", json["file_name"]
    end

    test "#{klass} - s3_after" do
      assert_enqueued_jobs(0) do
        post url_for([:s3_after, :console, :api, klass]), params: { s3_path: "foo", type: klass.to_s, file_id: nil }
        assert_response 422
      end

      test_path = "#{Folio::S3Client::TEST_PATH}/test-#{klass.model_name.singular}.gif"
      FileUtils.mkdir_p(File.dirname(test_path))
      FileUtils.cp(Folio::Engine.root.join("test/fixtures/folio/test.gif"), test_path)

      assert_difference("#{klass}.count", 1) do
        perform_enqueued_jobs do
          post url_for([:s3_after, :console, :api, klass]), params: { s3_path: "test-#{klass.model_name.singular}.gif", type: klass.to_s, file_id: nil }
          assert_response(:ok)
        end
      end
    end

    test "#{klass} - s3_after with file id" do
      file = create(klass.model_name.singular, file_name: "foo.gif")

      assert_enqueued_jobs(0) do
        post url_for([:s3_after, :console, :api, klass]), params: { s3_path: "foo", type: klass.to_s, file_id: file.id }
        assert_response 422
      end

      test_path = "#{Folio::S3Client::TEST_PATH}/test-#{klass.model_name.singular}.gif"
      FileUtils.mkdir_p(File.dirname(test_path))
      FileUtils.cp(Folio::Engine.root.join("test/fixtures/folio/test.gif"), test_path)

      assert_not_equal("test.gif", file.file_name)

      assert_difference("#{klass}.count", 0) do
        perform_enqueued_jobs do
          post url_for([:s3_after, :console, :api, klass]), params: { s3_path: "test-#{klass.model_name.singular}.gif", type: klass.to_s, file_id: file.id }
          assert_response(:ok)
        end
      end

      assert_equal("test-#{klass.model_name.singular}.gif", file.reload.file_name)
    end

    test "#{klass} - update" do
      file = create(klass.model_name.singular)
      put url_for([:console, :api, file]), params: {
        file: {
          attributes: {
            tags: ["foo"],
          }
        }
      }
      assert_response(:success)
      assert_equal(["foo"], response.parsed_body["data"]["attributes"]["tags"])
    end

    test "#{klass} - destroy" do
      file = create(klass.model_name.singular)
      assert klass.exists?(file.id)
      delete url_for([:console, :api, file])
      assert_response(:success)
      assert_not klass.exists?(file.id)
    end

    test "#{klass} - tag" do
      files = create_list(klass.model_name.singular, 2)
      assert_equal([], files.first.tag_list)
      assert_equal([], files.second.tag_list)

      post url_for([:tag, :console, :api, klass]), params: {
        file_ids: files.pluck(:id),
        tags: ["a", "b"],
      }

      assert_equal(["a", "b"], files.first.reload.tag_list.sort)
      assert_equal(["a", "b"], files.second.reload.tag_list.sort)
    end

    test "#{klass} - mass_destroy" do
      files = create_list(klass.model_name.singular, 3)
      assert_equal(3, klass.count)
      ids = files.first(2).map(&:id).join(",")
      delete url_for([:mass_destroy, :console, :api, klass, ids: ids])
      assert_equal(1, klass.count)
    end

    test "#{klass} - change_file" do
      file = create(klass.model_name.singular)
      assert_not_equal("test-black.gif", file.file_name)
      post url_for([:change_file, :console, :api, file]), params: {
        file: {
          attributes: {
            file: fixture_file_upload("test/fixtures/folio/test-black.gif"),
          }
        }
      }
      assert_response(:success)
      assert_equal("test-black.gif", response.parsed_body["data"]["attributes"]["file_name"])
    end

    test "#{klass} - mass_download" do
      files = create_list(klass.model_name.singular, 2)
      ids = files.map(&:id).join(",")
      get url_for([:mass_download, :console, :api, klass, ids: ids])
      assert_response(:ok)
    end
  end
end
