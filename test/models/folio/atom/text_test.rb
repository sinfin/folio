# frozen_string_literal: true

require "test_helper"

class Folio::Atom::TextTest < ActionDispatch::IntegrationTest
  test "renders" do
    create(:folio_site)

    atom = create_atom(Folio::Atom::Text,
                       content: "<p>bar</p>",
                       placement: create(:folio_page, title: "cat"))
    visit page_path(atom.placement, locale: :cs)
    assert_equal("cat", page.find("h1").text)
    assert_equal("bar", page.find("p").text)
  end
end
