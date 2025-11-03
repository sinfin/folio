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

    test "#{klass} - destroy indestructible" do
      file = create(klass.model_name.singular)
      assert klass.exists?(file.id)
      file.update_column(:file_placements_count, 1)

      delete url_for([:console, :api, file, format: :json])

      assert_response(:unprocessable_entity)
      assert klass.exists?(file.id)
      assert_equal 1, response.parsed_body["errors"].size
      assert_equal 422, response.parsed_body["errors"].first["status"]
      assert_equal "ActiveRecord::RecordNotDestroyed", response.parsed_body["errors"].first["title"]
      assert_equal I18n.t("folio.file.cannot_destroy_file_with_placements"), response.parsed_body["errors"].first["detail"]
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

    if klass.human_type == "image"
      test "#{klass} - update_thumbnails_crop" do
        file = create(klass.model_name.singular)

        # Set initial thumbnail_sizes to verify they get cleared
        file.update!(thumbnail_sizes: {
          "160x90#" => { "uid" => "test_uid_1", "webp_uid" => "test_webp_uid_1" },
          "320x180#" => { "uid" => "test_uid_2", "webp_uid" => "test_webp_uid_2" }
        })

        patch url_for([:update_thumbnails_crop, :console, :api, file, format: :json]), params: {
          crop: {
            x: 0.0,
            y: 0.1,
          },
          ratio: "16:9",
          thumbnail_size_keys: ["160x90#", "320x180#"]
        }

        assert_response(:success)
        assert response.parsed_body["data"].present?

        file.reload

        # Check thumbnail_configuration is updated
        assert_equal 0.0, file.thumbnail_configuration["ratios"]["16:9"]["crop"]["x"]
        assert_equal 0.1, file.thumbnail_configuration["ratios"]["16:9"]["crop"]["y"]

        # Check thumbnail_sizes are reset with new structure
        assert_nil file.thumbnail_sizes["160x90#"][:uid]
        assert_nil file.thumbnail_sizes["160x90#"][:signature]
        assert_equal 160, file.thumbnail_sizes["160x90#"][:width]
        assert_equal 90, file.thumbnail_sizes["160x90#"][:height]
        assert file.thumbnail_sizes["160x90#"][:url].present?

        assert_nil file.thumbnail_sizes["320x180#"][:uid]
        assert_nil file.thumbnail_sizes["320x180#"][:signature]
        assert_equal 320, file.thumbnail_sizes["320x180#"][:width]
        assert_equal 180, file.thumbnail_sizes["320x180#"][:height]
        assert file.thumbnail_sizes["320x180#"][:url].present?
      end
    end
  end
end
