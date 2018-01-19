# frozen_string_literal: true

require 'test_helper'

class Folio::Console::Nodes::TranslationsCellTest < Cell::TestCase
  controller Folio::Console::BaseController

  test 'show' do
    node = create(:folio_node)
    html = cell('folio/console/nodes/translations', node).(:show)
    assert html.has_css?('.folio-console-nodes-translations')
  end
end
