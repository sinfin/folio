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
end
