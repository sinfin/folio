# frozen_string_literal: true

require "test_helper"

class Folio::FileTest < ActiveSupport::TestCase
  test "touches placements and their models" do
    page = create(:folio_page)
    updated_at = page.updated_at

    image = create(:folio_image)
    page.images << image
    assert page.reload.updated_at > updated_at

    updated_at = page.updated_at
    assert image.reload.update!(tag_list: "foo")
    assert page.reload.updated_at > updated_at
  end

  test "touches page through atoms" do
    page = create(:folio_page)
    image = create(:folio_image)
    atom = create_atom(Dummy::Atom::DaVinci, placement: page, cover: image)

    atom_updated_at = atom.reload.updated_at
    page_updated_at = page.reload.updated_at

    assert image.reload.update!(tag_list: "foo")
    assert atom.reload.updated_at > atom_updated_at
    assert page.reload.updated_at > page_updated_at
  end

  test "cannot be destroyed when used" do
    image = create(:folio_image)
    assert image.destroy

    image = create(:folio_image)
    create_atom(Dummy::Atom::DaVinci, cover: image)
    assert_not image.destroy
  end
end
