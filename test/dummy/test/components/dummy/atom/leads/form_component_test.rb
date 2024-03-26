# frozen_string_literal: true

require "test_helper"

class Dummy::Atom::Leads::FormComponentTest < Folio::ComponentTest
  def test_render
    atom = create_atom(Dummy::Atom::Leads::Form)

    render_inline(Dummy::Atom::Leads::FormComponent.new(atom:))

    assert_selector(".d-atom-leads-form")
  end
end
