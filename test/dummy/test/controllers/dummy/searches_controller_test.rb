# frozen_string_literal: true

require "test_helper"

class Dummy::SearchesControllerTest < ActionDispatch::IntegrationTest
  test "show" do
    create(:folio_site)

    get dummy_search_path
    assert_response(:ok)
    assert_select(".d-searches-show__title")
    assert_select(".d-searches-show__no-results")

    get dummy_search_path(q: "foo")
    assert_response(:ok)
    assert_select(".d-searches-show__title")
    assert_select(".d-searches-show__no-results")

    create(:folio_page, title: "bar")
    get dummy_search_path(q: "foo")
    assert_response(:ok)
    assert_select(".d-searches-show__title")
    assert_select(".d-searches-show__no-results")

    create(:folio_page, title: "foo")
    get dummy_search_path(q: "foo")
    assert_response(:ok)
    assert_select(".d-searches-show__title")
    assert_select(".d-searches-show__results")
    assert_select(".d-searches-show__tabs")
    assert_select(".d-searches-show__results-title")
    assert_select(".d-searches-show__no-results", 0)

    create(:folio_page, title: "foo")
    get dummy_search_path(q: "foo", tab: Folio::Page.model_name.human(count: 2))
    assert_response(:ok)
    assert_select(".d-searches-show__title")
    assert_select(".d-searches-show__results")
    assert_select(".d-searches-show__tabs")
    assert_select(".d-searches-show__results-title", 0)
    assert_select(".d-searches-show__no-results", 0)
  end

  test "autocomplete" do
    create(:folio_site)

    get autocomplete_dummy_search_path
    assert_response(:ok)
    page = Capybara.string(response.parsed_body["data"])
    assert_equal(0, page.find_css(".d-searches-autocomplete__klass").size)
    assert_equal(1, page.find_css(".d-searches-autocomplete__no-results").size)

    get autocomplete_dummy_search_path(q: "foo")
    assert_response(:ok)
    page = Capybara.string(response.parsed_body["data"])
    assert_equal(0, page.find_css(".d-searches-autocomplete__klass").size)
    assert_equal(1, page.find_css(".d-searches-autocomplete__no-results").size)

    create(:folio_page, title: "bar")
    get autocomplete_dummy_search_path(q: "foo")
    assert_response(:ok)
    page = Capybara.string(response.parsed_body["data"])
    assert_equal(0, page.find_css(".d-searches-autocomplete__klass").size)
    assert_equal(1, page.find_css(".d-searches-autocomplete__no-results").size)

    create(:folio_page, title: "foo")
    get autocomplete_dummy_search_path(q: "foo")
    assert_response(:ok)
    page = Capybara.string(response.parsed_body["data"])
    assert_equal(1, page.find_css(".d-searches-autocomplete__klass").size)
    assert_equal(0, page.find_css(".d-searches-autocomplete__no-results").size)
  end
end
