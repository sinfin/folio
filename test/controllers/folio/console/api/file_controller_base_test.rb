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

    if klass.new.thumbnailable?
      test "#{klass} - destroy with thumbnail_sizes" do
        file = create(klass.model_name.singular)

        # Set thumbnail_sizes to trigger the FrozenError scenario before the fix
        file.update!(thumbnail_sizes: { "160x90#" => { uid: "test_uid" } })

        assert klass.exists?(file.id)

        delete url_for([:console, :api, file, format: :json])

        assert_response(:success)
        assert_not klass.exists?(file.id)
      end
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

    test "#{klass} - pagination renders reload_url with filter params" do
      get url_for([:pagination, :console, :api, klass, format: :json]), params: {
        page: 2,
        created_by_current_user: "1",
      }
      assert_response(:ok)

      html = Nokogiri::HTML(response.parsed_body["data"])
      pagy_el = html.at_css(".f-c-ui-pagy")
      assert pagy_el, "Pagy component should be present"

      reload_url = pagy_el["data-f-c-ui-pagy-reload-url-value"]
      assert reload_url.present?, "reload_url should be set"
      assert_includes reload_url, "created_by_current_user=1", "reload_url should preserve filter"
      assert_includes reload_url, "page=2", "reload_url should preserve page"
    end

    if %w[image video].include?(klass.human_type)
      test "#{klass} - index with by_file_name sorts newest first" do
        created_at = Time.zone.parse("2026-04-29 14:00:00")
        query = "cs279api#{klass.human_type}"
        older = create(klass.model_name.singular,
                       site: @site,
                       file_name: query,
                       created_at: created_at - 1.hour)
        lower_id = create(klass.model_name.singular,
                          site: @site,
                          file_name: "#{query}-lower",
                          created_at:)
        higher_id = create(klass.model_name.singular,
                           site: @site,
                           file_name: "#{query}-higher",
                           created_at:)
        expected_ids = [higher_id.id, lower_id.id, older.id]

        get url_for([:console, :api, klass, format: :json]), params: { by_file_name: query }

        actual_ids = response.parsed_body["data"]
                             .map { |record| record["id"].to_i }
                             .select { |id| expected_ids.include?(id) }

        assert_response :success
        assert_equal expected_ids, actual_ids
      end
    end

    test "#{klass} - pagination preserves explicit request_path after picker upload refresh" do
      create_list(klass.model_name.singular, Folio::Console::FileControllerBase::PAGY_ITEMS + 1)

      request_path = url_for([:console, klass, action: :index_for_picker, only_path: true])

      get url_for([:pagination, :console, :api, klass, format: :json]), params: {
        page: 1,
        request_path:
      }
      assert_response(:ok)

      html = Nokogiri::HTML(response.parsed_body["data"])
      pagy_el = html.at_css(".f-c-ui-pagy")
      assert pagy_el, "Pagy component should be present"

      reload_url = pagy_el["data-f-c-ui-pagy-reload-url-value"]
      reload_params = Rack::Utils.parse_query(URI.parse(reload_url).query)

      assert_equal request_path, reload_params["request_path"]

      page_link = html.at_css(".f-c-ui-pagy a[href*='page=2']")
      assert page_link, "Pagy component should render page links"
      assert_includes page_link["href"], request_path
      assert_not_includes page_link["href"], "/console/api/"
      assert_not_includes page_link["href"], "request_path"
    end

    test "#{klass} - batch_bar" do
      get url_for([:batch_bar, :console, :api, klass, format: :json])
      assert_response(:ok)
    end

    test "#{klass} - open_batch_form merges file_attributes into form" do
      files = create_list(klass.model_name.singular, 2, author: "author_from_db")
      file_ids = files.map(&:id)

      get url_for([:batch_bar, :console, :api, klass, format: :json])

      assert_response(:ok)

      post url_for([:handle_batch_queue, :console, :api, klass, format: :json]), params: {
        queue: {
          add: file_ids,

        }
      }

      assert_response(:ok)

      # empty input, same values in DB
      post url_for([:open_batch_form, :console, :api, klass, format: :json]), params: {
        file_attributes: {
          author: "",
        }
      }

      assert_response(:ok)
      author_input = Nokogiri::HTML(response.parsed_body["data"]).at_css('input[name="file_attributes[author]"]')
      assert_equal "author_from_db", author_input["value"]

      # no input, different values in DB
      files.first.update!(author: "new_autor")

      post url_for([:open_batch_form, :console, :api, klass, format: :json]), params: {
        file_attributes: {
          author: "",
        }
      }

      assert_response(:ok)
      author_input = Nokogiri::HTML(response.parsed_body["data"]).at_css('input[name="file_attributes[author]"]')
      assert_nil author_input["value"]
      assert_equal "Různé hodnoty", author_input["placeholder"]

      # filled in input, different than stored values (input wins)
      post url_for([:open_batch_form, :console, :api, klass, format: :json]), params: {
        file_attributes: {
          author: "author_from_request"
        }
      }

      assert_response(:ok)
      author_input = Nokogiri::HTML(response.parsed_body["data"]).at_css('input[name="file_attributes[author]"]')
      assert_equal "author_from_request", author_input["value"]

      # filled in input, same as stored value
      files.each { |file| file.update!(author: "auhtor_from_db") }

      post url_for([:open_batch_form, :console, :api, klass, format: :json]), params: {
        file_attributes: {
          author: "author_from_db",
        }
      }

      assert_response(:ok)
      author_input = Nokogiri::HTML(response.parsed_body["data"]).at_css('input[name="file_attributes[author]"]')
      assert_equal "author_from_db", author_input["value"]

      # filled in input, stored values are empty
      files.each { |file| file.update!(author: "") }

      post url_for([:open_batch_form, :console, :api, klass, format: :json]), params: {
        file_attributes: {
          author: "override_from_request",
        }
      }

      assert_response(:ok)
      author_input = Nokogiri::HTML(response.parsed_body["data"]).at_css('input[name="file_attributes[author]"]')
      assert_equal "override_from_request", author_input["value"]
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

    test "#{klass} - file_picker_file_hash resolves numeric :id by primary key, not a colliding numeric slug" do
      target = create(klass.model_name.singular)
      decoy = create(klass.model_name.singular)
      # Legacy file whose (file-name derived) slug equals another file's id,
      # e.g. a file uploaded as "349444.jpg" -> slug "349444" colliding with id 349444.
      decoy.update_column(:slug, target.id.to_s)

      # The console JS sends the file's numeric id (not its slug) in :id.
      slug_url = url_for([:file_picker_file_hash, :console, :api, target, format: :json])
      get slug_url.sub("/#{target.to_param}/", "/#{target.id}/")

      assert_response(:success)
      assert_equal(target.id, response.parsed_body["data"]["id"].to_i,
                   "numeric :id must resolve by primary key, not by decoy ##{decoy.id}'s colliding numeric slug")
    end

    if klass.human_type == "image"
      test "#{klass} - update_thumbnails_crop writes crop under the bucket label and every exact ratio of the keys" do
        file = create(klass.model_name.singular)
        file.update!(thumbnail_sizes: {
          "480x320#" => { "uid" => "test_uid_1" },
          "306x208#" => { "uid" => "test_uid_2" },
          "400x250#" => { "uid" => "test_uid_3" },
        })

        patch url_for([:update_thumbnails_crop, :console, :api, file, format: :json]), params: {
          ratio: "3:2",
          group_type: "crop",
          crop: { x: 0.4, y: 0.6 }
        }

        assert_response(:success)
        file.reload
        ratios = file.thumbnail_configuration["ratios"]
        assert_equal({ "x" => 0.4, "y" => 0.6 }, ratios["3:2"]["crop"])
        assert_equal({ "x" => 0.4, "y" => 0.6 }, ratios["153:104"]["crop"])
        assert_nil ratios["8:5"]
      end

      test "#{klass} - update_thumbnails_crop propagates a main crop to every detailed ratio in the family" do
        file = create(klass.model_name.singular)
        file.update!(thumbnail_sizes: {
          "200x120#" => { "uid" => "test_uid_1" },
          "400x250#" => { "uid" => "test_uid_2" },
          "800x450#" => { "uid" => "test_uid_3" },
        })

        patch url_for([:update_thumbnails_crop, :console, :api, file, format: :json]), params: {
          ratio: "16:9",
          group_type: "main_crop",
          crop: { x: 0.4, y: 0.6 }
        }

        assert_response(:success)
        ratios = file.reload.thumbnail_configuration["ratios"]
        assert_equal({ "x" => 0.4, "y" => 0.6 }, ratios["5:3"]["crop"])
        assert_equal({ "x" => 0.4, "y" => 0.6 }, ratios["8:5"]["crop"])
        assert_equal({ "x" => 0.4, "y" => 0.6 }, ratios["16:9"]["crop"])

        component = Nokogiri::HTML.fragment(response.parsed_body["data"])
        assert_equal 4, component.css(
          '[data-f-c-files-show-thumbnails-crop-edit-state-value="waiting-for-thumbnail"]'
        ).size
      end

      test "#{klass} - update_thumbnails_crop persists forced-gravity sizes under their intrinsic ratio" do
        file = create(klass.model_name.singular)
        file.update!(thumbnail_sizes: { "400x250#c" => { "uid" => "test_uid_1" } })

        patch url_for([:update_thumbnails_crop, :console, :api, file, format: :json]), params: {
          ratio: "16:9",
          group_type: "main_crop",
          crop: { x: 0.4, y: 0.6 }
        }

        assert_response(:success)
        ratios = file.reload.thumbnail_configuration["ratios"]
        assert_equal({ "x" => 0.4, "y" => 0.6 }, ratios["16:9"]["crop"])
        assert_equal({ "x" => 0.4, "y" => 0.6 }, ratios["8:5"]["crop"])
      end

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
          group_type: "crop"
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
        assert_equal file.temporary_url("160x90#.webp"), file.thumbnail_sizes["160x90#"][:webp_url]

        assert_nil file.thumbnail_sizes["320x180#"][:uid]
        assert_nil file.thumbnail_sizes["320x180#"][:signature]
        assert_equal 320, file.thumbnail_sizes["320x180#"][:width]
        assert_equal 180, file.thumbnail_sizes["320x180#"][:height]
        assert file.thumbnail_sizes["320x180#"][:url].present?
        assert_equal file.temporary_url("320x180#.webp"), file.thumbnail_sizes["320x180#"][:webp_url]
      end

      test "#{klass} - update_thumbnails_crop destroys old thumbnail uids asynchronously" do
        file = create(klass.model_name.singular)
        file.update!(thumbnail_sizes: { "200x100#" => { "uid" => "uid-async-1", "webp_uid" => "uid-async-2" } })

        assert_enqueued_with(job: Folio::DestroyThumbnailUidsJob) do
          patch url_for([:update_thumbnails_crop, :console, :api, file, format: :json]),
                params: { ratio: "2:1", group_type: "crop", crop: { x: 0.5, y: 0.5 } },
                as: :json
        end
      end

      test "#{klass} - update_thumbnails_crop returns the complete thumbnails component" do
        file = create(klass.model_name.singular)
        file.update!(thumbnail_sizes: { "160x90#" => { "uid" => "u1", "url" => "https://example.com/160x90.jpg" } })

        patch url_for([:update_thumbnails_crop, :console, :api, file, format: :json]), params: {
          crop: { x: 0.0, y: 0.1 },
          ratio: "16:9",
          group_type: "crop"
        }

        assert_response(:success)
        component_html = response.parsed_body["data"]
        assert component_html.include?("f-c-files-show-thumbnails")
        assert component_html.include?("f-c-files-show-thumbnails-ratio")
        assert component_html.include?("f-c-files-show-thumbnails-list-group")

        component = Nokogiri::HTML.fragment(component_html)
        assert_equal 2, component.css(
          '[data-f-c-files-show-thumbnails-crop-edit-state-value="waiting-for-thumbnail"]'
        ).size
      end

      test "#{klass} - update_thumbnails_crop destroys uids stored under symbol keys" do
        file = create(klass.model_name.singular)
        file.update!(thumbnail_sizes: { "200x100#" => { uid: "sym-uid-1", webp_uid: "sym-webp-uid-1" } })

        assert_enqueued_with(job: Folio::DestroyThumbnailUidsJob, args: [["sym-uid-1", "sym-webp-uid-1"]]) do
          patch url_for([:update_thumbnails_crop, :console, :api, file, format: :json]),
                params: { ratio: "2:1", group_type: "crop", crop: { x: 0.5, y: 0.5 } },
                as: :json
        end
      end
    end
  end
end
