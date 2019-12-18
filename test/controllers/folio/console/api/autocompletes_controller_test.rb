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

  test 'selectize' do
    get selectize_console_api_autocomplete_path(klass: 'Folio::Page', q: 'foo')
    json = JSON.parse(response.body)
    assert_equal([], json['data'])

    create(:folio_page, title: 'Foo bar baz')
    get selectize_console_api_autocomplete_path(klass: 'Folio::Page', q: 'foo')
    json = JSON.parse(response.body)
    assert_equal(1, json['data'].size)
    assert_equal('Foo bar baz', json['data'][0]['text'])

    @admin.forget_me!
    sign_out @admin
    get selectize_console_api_autocomplete_path(klass: 'Folio::Page', q: 'a')
    json = JSON.parse(response.body)
    assert_equal(401, json['errors'][0]['status'])
  end

  test 'react_select' do
    get react_select_console_api_autocomplete_path(class_names: 'Folio::Page', q: 'foo')
    json = JSON.parse(response.body)
    assert_equal([], json['data'])

    create(:folio_page, title: 'Foo bar baz')
    get react_select_console_api_autocomplete_path(class_names: 'Folio::Page', q: 'foo')
    json = JSON.parse(response.body)
    assert_equal(1, json['data'].size)
    assert_equal('Foo bar baz', json['data'][0]['text'])
    assert_equal('Folio::Page', json['data'][0]['type'])

    @admin.forget_me!
    sign_out @admin
    get react_select_console_api_autocomplete_path(class_names: 'Folio::Page', q: 'a')
    json = JSON.parse(response.body)
    assert_equal(401, json['errors'][0]['status'])
  end
end
