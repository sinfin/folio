# frozen_string_literal: true

require "test_helper"

class Folio::Console::Api::LinksControllerTest < Folio::Console::BaseControllerTest
  include Folio::Engine.routes.url_helpers

  test "index" do
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
end
