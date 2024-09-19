# frozen_string_literal: true

require "test_helper"

class Dummy::Atom::Content::QuotationComponentTest < Folio::ComponentTest
  def test_render
    atom = create_atom(Dummy::Atom::Content::Quotation, :content)

    render_inline(Dummy::Atom::Content::QuotationComponent.new(atom:))

    assert_selector(".d-atom-content-quotation")
  end
end
