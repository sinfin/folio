# frozen_string_literal: true

require 'test_helper'

class Folio::Console::Nodes::TranslationsCellTest < Cell::TestCase
  controller Folio::Console::BaseController

  test 'hide with single locale' do
    node = create(:folio_node)
    html = cell('folio/console/nodes/translations', node).(:show)
    refute html.has_css?('.folio-console-nodes-translations')
  end

  test 'show with mulitple locales' do
    site = create(:folio_site, locales: [:cs, :en])
    node = create(:folio_node, site: site)
    html = cell('folio/console/nodes/translations', node).(:show)
    assert html.has_css?('.folio-console-nodes-translations')
  end
end
