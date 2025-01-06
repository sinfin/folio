# frozen_string_literal: true

require "test_helper"

class Folio::ClonableTest < ActiveSupport::TestCase
  test "create clone of page" do
    page = create(:folio_page)

    create_atom(Dummy::Atom::Contents::Text,
            placement: page,
            content: "Původní text")

    image = create(:folio_file_image)

    create_atom(Dummy::Atom::Cards::Image,
                placement: page,
                title: "Původní titulek",
                description: "Původní popis",
                url: "https://example.com",
                cover: image)
    page.cover = image

    original_attributes = page.attributes
    clone = Folio::Clonable::Cloner.new(page).create_clone

    clone.title = "clone"
    assert clone.valid?

    assert_not_equal page.atoms, clone.atoms
    assert_equal page.cover, clone.cover
    assert_not_equal page.cover_placement, clone.cover_placement

    clone.atoms.first.update!(content: "Změněný text")
    clone.atoms.last.update!(title: "Změněný titulek", description: "Změněný popis", url: "https://example2.com")

    clone.update!(
        title: "Nový titulek",
        perex: "Nový perex",
        published_at: Time.current,
        published: true,
      )

    page.reload
    assert_equal original_attributes.without("created_at", "updated_at"), page.attributes.without("created_at", "updated_at")
    assert_equal "Původní text", page.atoms.first.content
    assert_not_equal page.atoms.first.content, clone.atoms.first.content
    assert_equal image, page.atoms.second.cover
    assert_equal image, clone.atoms.second.cover
  end
end
