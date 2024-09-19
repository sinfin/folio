# frozen_string_literal: true

require "test_helper"

class Dummy::Atom::Form::Leads::FormComponentTest < Folio::ComponentTest
  def test_render
    atom = create_atom(Dummy::Atom::Form::Leads::Form)

    render_inline(Dummy::Atom::Form::Leads::FormComponent.new(atom:))

    assert_selector(".d-atom-form-leads-form")
  end
end
