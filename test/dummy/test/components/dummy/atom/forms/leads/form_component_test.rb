# frozen_string_literal: true

require "test_helper"

class Dummy::Atom::Forms::Leads::FormComponentTest < Folio::ComponentTest
  def test_render
    atom = create_atom(Dummy::Atom::Forms::Leads::Form)

    render_inline(Dummy::Atom::Forms::Leads::FormComponent.new(atom:))

    assert_selector(".d-atom-forms-leads-form")
  end
end
