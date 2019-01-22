# frozen_string_literal: true

require 'test_helper'

class Folio::Console::LinksControllerTest < Folio::Console::BaseControllerTest
  include Folio::Engine.routes.url_helpers

  test 'index' do
    I18n.with_locale(:cs) do
      get console_links_path
      assert_equal([], JSON.parse(response.body))

      create(:folio_page, title: 'Foo', slug: 'foo')
      get console_links_path
      assert_equal([{ 'name' => 'Stránka - Foo', 'url' => '/cs/foo' }],
                   JSON.parse(response.body))

      create(:folio_page, title: 'Bar', slug: 'bar')
      get console_links_path
      assert_equal([{ 'name' => 'Stránka - Bar', 'url' => '/cs/bar' },
                    { 'name' => 'Stránka - Foo', 'url' => '/cs/foo' }],
                   JSON.parse(response.body))

      Folio::Console::LinksController.class_eval do
        private

          def additional_links
            [{ name: 'A - test', url: 'url' }]
          end
      end

      get console_links_path
      assert_equal([{ 'name' => 'A - test', 'url' => 'url' },
                    { 'name' => 'Stránka - Bar', 'url' => '/cs/bar' },
                    { 'name' => 'Stránka - Foo', 'url' => '/cs/foo' }],
                   JSON.parse(response.body))
    end
  end
end
