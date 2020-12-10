# frozen_string_literal: true

require "test_helper"

class Folio::Console::Api::TagsControllerTest < Folio::Console::BaseControllerTest
  test "react_select" do
    page = create(:folio_page)

    get url_for([:react_select, :console, :api, :tags])
    assert_response :success
    assert_equal([], response.parsed_body["data"])

    one = ActsAsTaggableOn::Tag.create!(name: "one")
    two = ActsAsTaggableOn::Tag.create!(name: "two")

    get url_for([:react_select, :console, :api, :tags])
    assert_response :success
    assert_equal([], response.parsed_body["data"])

    ActsAsTaggableOn::Tagging.create!(taggable: page,
                                      tag: one,
                                      context: "tags")

    get url_for([:react_select, :console, :api, :tags])
    assert_response :success
    assert_equal(["one"], response.parsed_body["data"])

    get url_for([:react_select, :console, :api, :tags, context: "custom"])
    assert_response :success
    assert_equal([], response.parsed_body["data"])

    ActsAsTaggableOn::Tagging.create!(taggable: page,
                                      tag: two,
                                      context: "custom")

    get url_for([:react_select, :console, :api, :tags, context: "custom"])
    assert_response :success
    assert_equal(["two"], response.parsed_body["data"])

    get url_for([:react_select, :console, :api, :tags, context: "custom", q: "tw"])
    assert_response :success
    assert_equal(["two"], response.parsed_body["data"])

    get url_for([:react_select, :console, :api, :tags, context: "custom", q: "foobarbaz"])
    assert_response :success
    assert_equal([], response.parsed_body["data"])

    get url_for([:react_select, :console, :api, :tags, q: "o"])
    assert_response :success
    assert_equal(["one"], response.parsed_body["data"])

    get url_for([:react_select, :console, :api, :tags, q: "foobarbaz"])
    assert_response :success
    assert_equal([], response.parsed_body["data"])
  end
end
