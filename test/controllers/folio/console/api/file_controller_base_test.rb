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

    test "#{klass} - batch_bar" do
      get url_for([:batch_bar, :console, :api, klass, format: :json])
      assert_response(:ok)
    end

    test "#{klass} - handle_batch_queue" do
      # cannot test session[*] sadly
      file = create(klass.model_name.singular)

      post url_for([:handle_batch_queue, :console, :api, klass, format: :json]), params: {
        queue: {
          add: [file.id],
        }
      }
      assert_response(:ok)

      parsed_component = Nokogiri::HTML(response.parsed_body["data"])
      assert_equal 1, parsed_component.css(".f-c-files-batch-bar").size
      assert_equal("1", parsed_component.css(".f-c-files-batch-bar__count").first.text.strip)

      post url_for([:handle_batch_queue, :console, :api, klass, format: :json]), params: {
        queue: {
          remove: [file.id],
        }
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

      post url_for([:handle_batch_queue, :console, :api, klass, format: :json]), params: { queue: { add: file_ids } }
      assert_response(:ok)

      parsed_component = Nokogiri::HTML(response.parsed_body["data"])
      assert_equal 1, parsed_component.css(".f-c-files-batch-bar").size
      assert_equal("3", parsed_component.css(".f-c-files-batch-bar__count").first.text.strip)

      # make file indestructible
      files.first.update_column(:file_placements_count, 1)

      delete url_for([:batch_delete, :console, :api, klass, format: :json]), params: { file_ids: }

      assert_response(:bad_request)
      assert_equal 3, klass.where(id: file_ids).count, "Don't delete file_ids when some of them are indestructible"

      # make file destructible
      files.first.update_column(:file_placements_count, 0)

      delete url_for([:batch_delete, :console, :api, klass, format: :json]), params: { file_ids: }

      assert_response(:ok)
      assert_equal 0, klass.where(id: file_ids).count, "Delete file_ids that were added to batch"

      parsed_component = Nokogiri::HTML(response.parsed_body["data"])
      assert_equal 1, parsed_component.css(".f-c-files-batch-bar").size
      assert_equal("0", parsed_component.css(".f-c-files-batch-bar__count").first.text.strip)
    end

    test "#{klass} - batch_download, batch_download_success, batch_download_failure, cancel_batch_download" do
      files = create_list(klass.model_name.singular, 3)
      file_ids = files.map(&:id)
      assert_equal 3, klass.where(id: file_ids).count

      post url_for([:batch_download, :console, :api, klass, format: :json]), params: { file_ids: }

      assert_response(:bad_request)
      assert_equal 3, klass.where(id: file_ids).count, "Don't download file_ids that were not added to batch"

      post url_for([:handle_batch_queue, :console, :api, klass, format: :json]), params: { queue: { add: file_ids } }
      assert_response(:ok)

      parsed_component = Nokogiri::HTML(response.parsed_body["data"])
      assert_equal 1, parsed_component.css(".f-c-files-batch-bar").size
      assert_equal 0, parsed_component.css(".f-c-files-batch-bar__download").size
      assert_equal("3", parsed_component.css(".f-c-files-batch-bar__count").first.text.strip)

      post url_for([:batch_download, :console, :api, klass, format: :json]), params: { file_ids: }
      assert_response(:ok)

      parsed_component = Nokogiri::HTML(response.parsed_body["data"])
      assert_equal 1, parsed_component.css(".f-c-files-batch-bar").size
      assert_equal 0, parsed_component.css(".f-c-files-batch-bar__download").size
      assert_equal 1, parsed_component.css(".f-c-files-batch-bar__download-pending").size
      assert_equal("3", parsed_component.css(".f-c-files-batch-bar__count").first.text.strip)

      post url_for([:batch_download_success, :console, :api, klass, format: :json]), params: { file_ids:, url: "/foo" }
      assert_response(:ok)

      parsed_component = Nokogiri::HTML(response.parsed_body["data"])
      assert_equal 1, parsed_component.css(".f-c-files-batch-bar").size
      assert_equal 1, parsed_component.css(".f-c-files-batch-bar__download").size
      assert_equal 0, parsed_component.css(".f-c-files-batch-bar__download-pending").size
      assert_equal("3", parsed_component.css(".f-c-files-batch-bar__count").first.text.strip)

      post url_for([:batch_download_failure, :console, :api, klass, format: :json]), params: { file_ids:, message: "foo!" }
      assert_response(:ok)

      parsed_component = Nokogiri::HTML(response.parsed_body["data"])
      assert_equal 1, parsed_component.css(".f-c-files-batch-bar").size
      assert_equal 1, parsed_component.css(".f-c-files-batch-bar__download").size
      assert_equal 0, parsed_component.css(".f-c-files-batch-bar__download-pending").size
      assert_equal("3", parsed_component.css(".f-c-files-batch-bar__count").first.text.strip)

      post url_for([:cancel_batch_download, :console, :api, klass, format: :json])
      assert_response(:ok)

      parsed_component = Nokogiri::HTML(response.parsed_body["data"])
      assert_equal 1, parsed_component.css(".f-c-files-batch-bar").size
      assert_equal 0, parsed_component.css(".f-c-files-batch-bar__download").size
      assert_equal 0, parsed_component.css(".f-c-files-batch-bar__download-pending").size
      assert_equal("3", parsed_component.css(".f-c-files-batch-bar__count").first.text.strip)
    end

    test "#{klass} - batch_update" do
      files = create_list(klass.model_name.singular, 3, attribution_licence: "bar")
      file_ids = files.map(&:id)
      assert_equal 3, klass.where(id: file_ids).count

      # init session so that we get the same session id in the next requests
      get url_for([:batch_bar, :console, :api, klass, format: :json])
      assert_response(:ok)

      post url_for([:handle_batch_queue, :console, :api, klass, format: :json]), params: { queue: { add: file_ids } }
      assert_response(:ok)

      parsed_component = Nokogiri::HTML(response.parsed_body["data"])
      assert_equal 1, parsed_component.css(".f-c-files-batch-bar").size
      assert_equal 0, parsed_component.css(".f-c-files-batch-bar__form-wrap").size

      post url_for([:open_batch_form, :console, :api, klass, format: :json])
      assert_response(:ok)

      assert_not_equal "foo", files.first.reload.author

      parsed_component = Nokogiri::HTML(response.parsed_body["data"])
      assert_equal 1, parsed_component.css(".f-c-files-batch-bar").size
      assert_equal 1, parsed_component.css(".f-c-files-batch-bar__form-wrap").size

      patch url_for([:batch_update, :console, :api, klass, format: :json]), params: {
        file_ids:,
        file_attributes: {
          author: "foo",
          attribution_licence: "",
        }
      }
      assert_response(:ok)

      assert_equal "foo", files.first.reload.author
      assert_equal "bar", files.first.reload.attribution_licence, "Don't update attribution_licence when blank"
    end

    test "#{klass} - file_picker_file_hash" do
      file = create(klass.model_name.singular)
      get url_for([:file_picker_file_hash, :console, :api, file, format: :json])
      assert_response(:success)
      assert_equal(file.id, response.parsed_body["data"]["id"].to_i)
    end
  end
end
