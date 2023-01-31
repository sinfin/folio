# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::ConsolePreviewBrokenAtomCellTest < Cell::TestCase
  test "show" do
    html = cell("dummy/ui/console_preview_broken_atom", Dummy::Atom::Text.new).(:show)
    assert html.has_css?(".d-ui-console-preview-broken-atom")
  end
end
