# frozen_string_literal: true

require "test_helper"

class Dummy::Atom::ContactFormCellTest < Cell::TestCase
  test "show" do
    create_and_host_site
    placement = create(:folio_page, site: @site)

    atom = create_atom(Dummy::Atom::ContactForm, placement:)
    html = cell(atom.class.cell_name, atom).(:show)
    assert html
  end
end