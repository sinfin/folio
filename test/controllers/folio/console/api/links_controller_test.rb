# frozen_string_literal: true

require "test_helper"

class Folio::Console::Api::LinksControllerTest < Folio::Console::BaseControllerTest
  include Folio::Engine.routes.url_helpers

  test "show" do
    I18n.with_locale(:cs) do
      get console_api_links_path
      assert_equal([], response.parsed_body["data"])

      page = create(:folio_page, title: "Foo", slug: "foo")
      get console_api_links_path
      assert_equal([{ "label" => "Stránka - Foo", "url" => "/foo", "title" => "Foo" }],
                   response.parsed_body["data"])

      create(:folio_page, title: "Bar", slug: "bar")
      get console_api_links_path
      assert_equal([{ "label" => "Stránka - Bar", "url" => "/bar", "title" => "Bar" },
                    { "label" => "Stránka - Foo", "url" => "/foo", "title" => "Foo" }],
                   response.parsed_body["data"])

      Folio::Console::Api::LinksController.class_eval do
        private
          def additional_links
            {
              Folio::MenuItem => Proc.new { |page| "url" }
            }
          end

          def rails_paths
            {
              root_path: "Homepage",
            }
          end
      end

      create(:folio_menu_item, title: "Test", target: page, menu: create(:folio_menu_page))

      get console_api_links_path
      assert_equal([{ "label" => "Homepage", "url" => "/", "title" => "Homepage" },
                    { "label" => "Odkaz - Test", "url" => "url", "title" => "Test" },
                    { "label" => "Stránka - Bar", "url" => "/bar", "title" => "Bar" },
                    { "label" => "Stránka - Foo", "url" => "/foo", "title" => "Foo" }],
                   response.parsed_body["data"])
    end
  end

  test "control_bar - href" do
    get control_bar_console_api_links_path(format: :json), params: {
      href: ""
    }

    assert_response :ok
    assert response.parsed_body["data"].include?("f-c-links-control-bar")

    get control_bar_console_api_links_path(format: :json), params: {
      href: "/foo"
    }

    assert_response :ok
    assert response.parsed_body["data"].include?("f-c-links-control-bar")
  end

  test "control_bar - url_json" do
    get control_bar_console_api_links_path(format: :json), params: {
      url_json: "{}",
    }

    assert_response :ok
    assert response.parsed_body["data"].include?("f-c-links-control-bar")

    get control_bar_console_api_links_path(format: :json), params: {
      url_json: { href: "/foo" }.to_json,
    }

    assert_response :ok
    assert response.parsed_body["data"].include?("f-c-links-control-bar")
  end

  test "modal_form" do
    get modal_form_console_api_links_path(format: :json), params: {
      url_json: "{}",
    }

    assert_response :ok
    assert response.parsed_body["data"].include?("f-c-links-modal-form")

    get modal_form_console_api_links_path(format: :json), params: {
      url_json: { href: "/foo" }.to_json,
    }

    assert_response :ok
    assert response.parsed_body["data"].include?("f-c-links-modal-form")
  end

  test "value" do
    get value_console_api_links_path(format: :json), params: {
      url_json: "{}",
    }

    assert_response :ok
    assert_not response.parsed_body["data"].include?("f-c-links-value")

    get value_console_api_links_path(format: :json), params: {
      url_json: { href: "/foo" }.to_json,
    }

    assert_response :ok
    assert response.parsed_body["data"].include?("f-c-links-value")
  end

  test "list" do
    create(:folio_page, title: "foobarbaz")

    get list_console_api_links_path(format: :json), params: {}

    assert_response :ok
    assert response.parsed_body["data"].include?("f-c-links-modal-list")
    assert response.parsed_body["data"].include?("foobarbaz")

    get list_console_api_links_path(format: :json), params: { q: "abc" }

    assert_response :ok
    assert response.parsed_body["data"].include?("f-c-links-modal-list")
    assert_not response.parsed_body["data"].include?("foobarbaz")
  end
end
