# frozen_string_literal: true

require Folio::Engine.root.join("test/test_helper")

class Dummy::Atom::Contents::QuotationComponentTest < Folio::ComponentTest
  def test_render
    atom = create_atom(Dummy::Atom::Contents::Quotation, :content)

    render_inline(Dummy::Atom::Contents::QuotationComponent.new(atom:))

    assert_selector(".d-atom-contents-quotation")
  end
end
