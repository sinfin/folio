# frozen_string_literal: true

require "test_helper"

class Folio::Console::Api::ImagesControllerTest < Folio::Console::BaseControllerTest
  test "index" do
    get url_for([:console, :api, Folio::Image])
    assert_response :success
  end

  test "create" do
    assert_difference("Folio::Image.count", 1) do
      post url_for([:console, :api, Folio::Image]), params: {
        file: {
          attributes: {
            file: fixture_file_upload("test/fixtures/folio/test.gif"),
            type: "Folio::Image",
          }
        }
      }
      assert_response :success
    end
  end

  test "update" do
    image = create(:folio_image)
    put url_for([:console, :api, image]), params: {
      file: {
        attributes: {
          tags: ["foo"],
        }
      }
    }
    assert_response(:success)
    json = JSON.parse(response.body)
    assert_equal(["foo"], json["data"]["attributes"]["tags"])
  end

  test "destroy" do
    image = create(:folio_image)
    assert Folio::Image.exists?(image.id)
    delete url_for([:console, :api, image])
    assert_response(:success)
    assert_not Folio::Image.exists?(image.id)
  end

  test "tag" do
    images = create_list(:folio_image, 2)
    assert_equal([], images.first.tag_list)
    assert_equal([], images.second.tag_list)

    post url_for([:tag, :console, :api, Folio::Image]), params: {
      file_ids: images.pluck(:id),
      tags: ["a", "b"],
    }

    assert_equal(["a", "b"], images.first.reload.tag_list.sort)
    assert_equal(["a", "b"], images.second.reload.tag_list.sort)
  end

  test "mass_destroy" do
    images = create_list(:folio_image, 3)
    assert_equal(3, Folio::Image.count)
    ids = images.first(2).map(&:id).join(",")
    delete url_for([:mass_destroy, :console, :api, Folio::Image, ids: ids])
    assert_equal(1, Folio::Image.count)
  end

  test "change_file" do
    image = create(:folio_image)
    assert_equal("test.gif", image.file_name)
    post url_for([:change_file, :console, :api, image]), params: {
      file: {
        attributes: {
          file: fixture_file_upload("test/fixtures/folio/test-black.gif"),
        }
      }
    }
    assert_response(:success)
    json = JSON.parse(response.body)
    assert_equal("test-black.gif", json["data"]["attributes"]["file_name"])
  end

  test "mass_download" do
    images = create_list(:folio_image, 2)
    ids = images.map(&:id).join(",")
    get url_for([:mass_download, :console, :api, Folio::Image, ids: ids])
    assert_response(:ok)
  end
end
