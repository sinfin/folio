# frozen_string_literal: true

require 'test_helper'

class Folio::Console::Pages::TranslationsCellTest < Cell::TestCase
  controller Folio::Console::BaseController

  test 'hide with single locale' do
    create(:folio_site, locales: [:cs]).reload
    page = create(:folio_page)
    html = cell('folio/console/pages/translations', page).(:show)
    assert_not html.has_css?('.folio-console-pages-translations')
  end

  test 'show with mulitple locales' do
    create(:folio_site, locales: [:cs, :en]).reload
    page = create(:folio_page)
    html = cell('folio/console/pages/translations', page).(:show)
    assert html.has_css?('.folio-console-pages-translations')
  end
end
