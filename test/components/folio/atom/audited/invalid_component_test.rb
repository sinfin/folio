# frozen_string_literal: true

require "test_helper"

class Folio::Atom::Audited::InvalidComponentTest < Folio::ComponentTest
  def test_render
    atom = create_atom(Folio::Atom::Audited::Invalid,
                       :atom_validation_errors,
                       :atom_audited_hash_json)

    render_inline(Folio::Atom::Audited::InvalidComponent.new(atom:))

    assert_no_selector(".f-atom-audited-invalid")
  end

  def test_render_console_preview
    atom = create_atom(Folio::Atom::Audited::Invalid,
                       :atom_validation_errors,
                       :atom_audited_hash_json)

    render_inline(Folio::Atom::Audited::InvalidComponent.new(atom:, atom_options: { console_preview: true }))

    assert_selector(".f-atom-audited-invalid")
  end
end
