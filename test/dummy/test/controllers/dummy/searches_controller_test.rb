# frozen_string_literal: true

require "test_helper"

class Dummy::SearchesControllerTest < Folio::IntegrationTest
  test "show" do
    create_and_host_site

    get dummy_search_path
    assert_response(:ok)
    assert_select(".d-searches-show__title")
    assert_select(".d-searches-show-contents__no-results")

    get dummy_search_path(q: "foo")
    assert_response(:ok)
    assert_select(".d-searches-show__title")
    assert_select(".d-searches-show-contents__no-results")

    create(:folio_page, title: "bar")
    get dummy_search_path(q: "foo")
    assert_response(:ok)
    assert_select(".d-searches-show__title")
    assert_select(".d-searches-show-contents__no-results")

    create(:folio_page, title: "foo")
    get dummy_search_path(q: "foo")
    assert_response(:ok)
    assert_select(".d-searches-show__title")
    assert_select(".d-searches-show-contents__results")
    assert_select(".d-searches-show-contents__tabs")
    assert_select(".d-searches-show-contents__results-title")
    assert_select(".d-searches-show-contents__no-results", 0)

    create(:folio_page, title: "foo")
    get dummy_search_path(q: "foo", tab: Folio::Page.model_name.human(count: 2))
    assert_response(:ok)
    assert_select(".d-searches-show__title")
    assert_select(".d-searches-show-contents__results")
    assert_select(".d-searches-show-contents__tabs")
    assert_select(".d-searches-show-contents__results-title", 0)
    assert_select(".d-searches-show-contents__no-results", 0)
  end

  test "show.json" do
    create_and_host_site

    get dummy_search_path(format: :json)
    assert_response(:ok)
    assert response.parsed_body["data"].include?("d-searches-show-contents__no-results")

    get dummy_search_path(q: "foo", format: :json)
    assert_response(:ok)
    assert response.parsed_body["data"].include?("d-searches-show-contents__no-results")

    create(:folio_page, title: "bar")
    get dummy_search_path(q: "foo", format: :json)
    assert_response(:ok)
    assert response.parsed_body["data"].include?("d-searches-show-contents__no-results")

    create(:folio_page, title: "foo")
    get dummy_search_path(q: "foo", format: :json)
    assert_response(:ok)
    assert response.parsed_body["data"].include?("d-searches-show-contents__results")
    assert response.parsed_body["data"].include?("d-searches-show-contents__tabs")
    assert response.parsed_body["data"].include?("d-searches-show-contents__results-title")
    assert_not response.parsed_body["data"].include?("d-searches-show-contents__no-results")

    create(:folio_page, title: "foo")
    get dummy_search_path(q: "foo", tab: Folio::Page.model_name.human(count: 2), format: :json)
    assert_response(:ok)
    assert response.parsed_body["data"].include?("d-searches-show-contents__results")
    assert response.parsed_body["data"].include?("d-searches-show-contents__tabs")
    assert_not response.parsed_body["data"].include?("d-searches-show-contents__results-title")
    assert_not response.parsed_body["data"].include?("d-searches-show-contents__no-results")
  end

  test "autocomplete" do
    create_and_host_site

    get autocomplete_dummy_search_path(format: :json)
    assert_response(:ok)
    page = Capybara.string(response.parsed_body["data"])
    assert_equal(0, page.find_css(".d-searches-autocomplete__klass").size)
    assert_equal(1, page.find_css(".d-searches-autocomplete__no-results").size)

    get autocomplete_dummy_search_path(q: "foo", format: :json)
    assert_response(:ok)
    page = Capybara.string(response.parsed_body["data"])
    assert_equal(0, page.find_css(".d-searches-autocomplete__klass").size)
    assert_equal(1, page.find_css(".d-searches-autocomplete__no-results").size)

    create(:folio_page, title: "bar")
    get autocomplete_dummy_search_path(q: "foo", format: :json)
    assert_response(:ok)
    page = Capybara.string(response.parsed_body["data"])
    assert_equal(0, page.find_css(".d-searches-autocomplete__klass").size)
    assert_equal(1, page.find_css(".d-searches-autocomplete__no-results").size)

    create(:folio_page, title: "foo")
    get autocomplete_dummy_search_path(q: "foo", format: :json)
    assert_response(:ok)
    page = Capybara.string(response.parsed_body["data"])
    assert_equal(1, page.find_css(".d-searches-autocomplete__klass").size)
    assert_equal(0, page.find_css(".d-searches-autocomplete__no-results").size)
  end
end
