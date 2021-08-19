# frozen_string_literal: true

require "test_helper"

class Folio::Console::Api::DocumentsControllerTest < Folio::Console::BaseControllerTest
  test "index" do
    get url_for([:console, :api, Folio::Document])
    assert_response :success
  end

  test "create" do
    assert_difference("Folio::Document.count", 1) do
      post url_for([:console, :api, Folio::Document]), params: {
        file: {
          attributes: {
            file: fixture_file_upload("test/fixtures/folio/test.gif"),
            type: "Folio::Document",
          }
        }
      }
      assert_response :success
    end
  end

  test "update" do
    document = create(:folio_document)
    put url_for([:console, :api, document]), params: {
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
    document = create(:folio_document)
    assert Folio::Document.exists?(document.id)
    delete url_for([:console, :api, document])
    assert_response(:success)
    assert_not Folio::Document.exists?(document.id)
  end

  test "tag" do
    documents = create_list(:folio_document, 2)
    assert_equal([], documents.first.tag_list)
    assert_equal([], documents.second.tag_list)

    post url_for([:tag, :console, :api, Folio::Document]), params: {
      file_ids: documents.pluck(:id),
      tags: ["a", "b"],
    }

    assert_equal(["a", "b"], documents.first.reload.tag_list.sort)
    assert_equal(["a", "b"], documents.second.reload.tag_list.sort)
  end

  test "mass_destroy" do
    documents = create_list(:folio_document, 3)
    assert_equal(3, Folio::Document.count)
    ids = documents.first(2).map(&:id).join(",")
    delete url_for([:mass_destroy, :console, :api, Folio::Document, ids: ids])
    assert_equal(1, Folio::Document.count)
  end

  test "change_file" do
    document = create(:folio_document)
    assert_equal("empty.pdf", document.file_name)
    post url_for([:change_file, :console, :api, document]), params: {
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
    documents = create_list(:folio_document, 2)
    ids = documents.map(&:id).join(",")
    get url_for([:mass_download, :console, :api, Folio::Document, ids: ids])
    assert_response(:ok)
  end
end
