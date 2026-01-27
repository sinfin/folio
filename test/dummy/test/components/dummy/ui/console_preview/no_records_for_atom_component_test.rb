# frozen_string_literal: true

require Folio::Engine.root.join("test/test_helper")

class Dummy::Ui::ConsolePreview::NoRecordsForAtomComponentTest < Folio::ComponentTest
  def test_render
    atom = create_atom(Dummy::Atom::Contents::Text, :content)

    render_inline(Dummy::Ui::ConsolePreview::NoRecordsForAtomComponent.new(atom:))

    assert_selector(".d-ui-console-preview-no-records-for-atom")
  end
end
