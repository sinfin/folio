# frozen_string_literal: true

require 'test_helper'

class Folio::Console::Nodes::TranslationsCellTest < Cell::TestCase
  controller Folio::Console::BaseController

  test 'hide with single locale' do
    create(:folio_site, locales: [:cs]).reload
    node = create(:folio_node)
    html = cell('folio/console/nodes/translations', node).(:show)
    assert_not html.has_css?('.folio-console-nodes-translations')
  end

  test 'show with mulitple locales' do
    create(:folio_site, locales: [:cs, :en]).reload
    node = create(:folio_node)
    html = cell('folio/console/nodes/translations', node).(:show)
    assert html.has_css?('.folio-console-nodes-translations')
  end
end
