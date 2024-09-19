# frozen_string_literal: true

require "test_helper"

class Dummy::Atom::Content::LeadParagraphComponentTest < Folio::ComponentTest
  def test_render
    atom = create_atom(Dummy::Atom::Content::LeadParagraph, :content)

    render_inline(Dummy::Atom::Content::LeadParagraphComponent.new(atom:))

    assert_selector(".d-atom-content-lead-paragraph")
  end
end
