# frozen_string_literal: true

require "test_helper"

class Dummy::Atom::QuotationComponentTest < Folio::ComponentTest
  def test_render
    atom = create_atom(Dummy::Atom::Quotation, :content)

    render_inline(Dummy::Atom::QuotationComponent.new(atom:))

    assert_selector(".d-atom-quotation")
  end
end
