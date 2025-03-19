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
      get url_for([:console, :api, klass])
      assert_response :success
    end

    test "#{klass} - update" do
      file = create(klass.model_name.singular)
      put url_for([:console, :api, file]), params: {
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
      delete url_for([:mass_destroy, :console, :api, klass, ids:])
      assert_equal(1, klass.count)
    end

    test "#{klass} - mass_download" do
      files = create_list(klass.model_name.singular, 2)
      ids = files.map(&:id).join(",")
      get url_for([:mass_download, :console, :api, klass, ids:])
      assert_response(:ok)
    end

    test "#{klass} - show" do
      file = create(klass.model_name.singular)
      get url_for([:console, :api, file, format: :json])
      assert_response(:ok)
      assert_match("f-c-files-show", response.parsed_body["data"])
    end
  end
end
