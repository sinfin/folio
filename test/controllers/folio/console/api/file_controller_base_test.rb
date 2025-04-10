# frozen_string_literal: true

require "test_helper"

class Folio::Console::Api::FileControllerBaseTest < Folio::Console::BaseControllerTest
  attr_reader :site

  [
    Folio::File::Document,
    Folio::File::Image,
    Folio::File::Video,
    Folio::File::Audio,
  ].each do |klass|
    test "#{klass} - index" do
      get url_for([:console, :api, klass, format: :json])
      assert_response :success
    end

    test "#{klass} - update" do
      file = create(klass.model_name.singular)
      put url_for([:console, :api, file, format: :json]), params: {
        file: {
          attributes: {
            tags: ["foo"],
            site_id: site.id,
          }
        }
      }
      assert_response(:success)
      assert_equal(["foo"], response.parsed_body["data"]["attributes"]["tags"])
    end

    test "#{klass} - destroy" do
      file = create(klass.model_name.singular)
      assert klass.exists?(file.id)

      delete url_for([:console, :api, file, format: :json])

      assert_response(:success)
      assert_not klass.exists?(file.id)
    end

    test "#{klass} - tag" do
      files = create_list(klass.model_name.singular, 2)
      assert_equal([], files.first.tag_list)
      assert_equal([], files.second.tag_list)

      post url_for([:tag, :console, :api, klass, format: :json]), params: {
        file_ids: files.pluck(:id),
        tags: ["a", "b"],
      }

      assert_equal(["a", "b"], files.first.reload.tag_list.sort)
      assert_equal(["a", "b"], files.second.reload.tag_list.sort)
    end

    test "#{klass} - show" do
      file = create(klass.model_name.singular)
      get url_for([:console, :api, file, format: :json])
      assert_response(:ok)
      assert_match("f-c-files-show", response.parsed_body["data"])
    end

    test "#{klass} - pagination" do
      get url_for([:pagination, :console, :api, klass, format: :json]), params: {
        page: 1,
      }
      assert_response(:ok)
      assert_match("f-c-ui-pagy", response.parsed_body["data"])
    end

    test "#{klass} - add_to_batch, remove_from_batch" do
      # cannot test session[*] sadly
      file = create(klass.model_name.singular)

      post url_for([:add_to_batch, :console, :api, klass, format: :json]), params: {
        file_ids: [file.id]
      }
      assert_response(:ok)

      parsed_component = Nokogiri::HTML(response.parsed_body["data"])
      assert_equal 1, parsed_component.css(".f-c-files-batch-bar").size
      assert_equal("1", parsed_component.css(".f-c-files-batch-bar__count").first.text.strip)

      post url_for([:remove_from_batch, :console, :api, klass, format: :json]), params: {
        file_ids: [file.id]
      }
      assert_response(:ok)

      parsed_component = Nokogiri::HTML(response.parsed_body["data"])
      assert_equal 1, parsed_component.css(".f-c-files-batch-bar").size
      assert_equal("0", parsed_component.css(".f-c-files-batch-bar__count").first.text.strip)
    end

    test "#{klass} - batch_delete" do
      files = create_list(klass.model_name.singular, 3)
      file_ids = files.map(&:id)
      assert_equal 3, klass.where(id: file_ids).count

      delete url_for([:batch_delete, :console, :api, klass, format: :json]), params: { file_ids: }

      assert_response(:bad_request)
      assert_equal 3, klass.where(id: file_ids).count, "Don't delete file_ids that were not added to batch"

      post url_for([:add_to_batch, :console, :api, klass, format: :json]), params: { file_ids: }
      assert_response(:ok)

      parsed_component = Nokogiri::HTML(response.parsed_body["data"])
      assert_equal 1, parsed_component.css(".f-c-files-batch-bar").size
      assert_equal("3", parsed_component.css(".f-c-files-batch-bar__count").first.text.strip)

      # make file indestructible
      files.first.update_column(:file_placements_size, 1)

      delete url_for([:batch_delete, :console, :api, klass, format: :json]), params: { file_ids: }

      assert_response(:bad_request)
      assert_equal 3, klass.where(id: file_ids).count, "Don't delete file_ids when some of them are indestructible"

      # make file destructible
      files.first.update_column(:file_placements_size, 0)

      delete url_for([:batch_delete, :console, :api, klass, format: :json]), params: { file_ids: }

      assert_response(:ok)
      assert_equal 0, klass.where(id: file_ids).count, "Delete file_ids that were added to batch"

      parsed_component = Nokogiri::HTML(response.parsed_body["data"])
      assert_equal 1, parsed_component.css(".f-c-files-batch-bar").size
      assert_equal("0", parsed_component.css(".f-c-files-batch-bar__count").first.text.strip)
    end

    test "#{klass} - batch_download" do
      files = create_list(klass.model_name.singular, 3)
      file_ids = files.map(&:id)
      assert_equal 3, klass.where(id: file_ids).count

      post url_for([:batch_download, :console, :api, klass, format: :json]), params: { file_ids: }

      assert_response(:bad_request)
      assert_equal 3, klass.where(id: file_ids).count, "Don't download file_ids that were not added to batch"

      post url_for([:add_to_batch, :console, :api, klass, format: :json]), params: { file_ids: }
      assert_response(:ok)

      parsed_component = Nokogiri::HTML(response.parsed_body["data"])
      assert_equal 1, parsed_component.css(".f-c-files-batch-bar").size
      assert_equal 0, parsed_component.css(".f-c-files-batch-bar__download").size
      assert_equal("3", parsed_component.css(".f-c-files-batch-bar__count").first.text.strip)

      post url_for([:batch_download, :console, :api, klass, format: :json]), params: { file_ids: }

      assert_response(:ok)
      assert_equal 3, klass.where(id: file_ids).count, "Delete file_ids that were added to batch"

      parsed_component = Nokogiri::HTML(response.parsed_body["data"])
      assert_equal 1, parsed_component.css(".f-c-files-batch-bar").size
      assert_equal 1, parsed_component.css(".f-c-files-batch-bar__download").size
      assert_equal("3", parsed_component.css(".f-c-files-batch-bar__count").first.text.strip)
    end
  end
end
