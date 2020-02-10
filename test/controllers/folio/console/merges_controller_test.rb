# frozen_string_literal: true

require 'test_helper'

class Folio::Console::MergesControllerTest < Folio::Console::BaseControllerTest
  include Folio::Engine.routes.url_helpers

  test 'new' do
    original = create(:folio_page)
    duplicate = create(:folio_page)

    visit new_console_merge_path('Folio::Page', original, duplicate)
    assert page.has_css?('.f-c-merges-form__form')
    assert_not page.has_css?('.f-c-merges-form__invalid')
  end

  test 'new - invalid' do
    original = create(:folio_page)
    duplicate = create(:folio_page)
    original.update_column(:title, nil)
    assert_not(original.valid?)

    visit new_console_merge_path('Folio::Page', original, duplicate)
    assert_not page.has_css?('.f-c-merges-form__form')
    assert page.has_css?('.f-c-merges-form__invalid')
  end

  test 'create' do
    original = create(:folio_page, title: 'foo')
    duplicate = create(:folio_page, title: 'bar')

    post console_merge_path('Folio::Page', original, duplicate), params: {
      merge: {
        title: 'duplicate',
      }
    }
    assert_response :success

    assert_equal('bar', original.reload.title)
    assert_not(Folio::Page.exists?(id: duplicate.id))
  end
end
