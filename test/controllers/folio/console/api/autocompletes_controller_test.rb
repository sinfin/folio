# frozen_string_literal: true

require 'test_helper'

class Folio::Console::Api::AutocompletesControllerTest < Folio::Console::BaseControllerTest
  test 'show' do
    get console_api_autocomplete_path(klass: 'Folio::Page', q: 'foo')
    json = JSON.parse(response.body)
    assert_equal([], json['data'])

    create(:folio_page, title: 'Foo bar baz')
    get console_api_autocomplete_path(klass: 'Folio::Page', q: 'foo')
    json = JSON.parse(response.body)
    assert_equal(['Foo bar baz'], json['data'])

    @admin.forget_me!
    sign_out @admin
    get console_api_autocomplete_path(klass: 'Folio::Page', q: 'a')
    json = JSON.parse(response.body)
    assert_equal(401, json['errors'][0]['status'])
  end
end
