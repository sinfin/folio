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
                url_json: { href: "https://example.com" },
                cover: image)
    page.cover = image

    document = create(:folio_file_document)
    create_atom(Dummy::Atom::Contents::Documents,
                placement: page,
                documents: [document],
                size: "medium")

    page.reload

    original_attributes = page.attributes
    clone = Folio::Clonable::Cloner.new(page).create_clone

    clone.title = "clone"
    assert clone.valid?

    original_text_atom = page.atoms.find { |atom| atom.is_a?(Dummy::Atom::Contents::Text) }
    original_image_atom = page.atoms.find { |atom| atom.is_a?(Dummy::Atom::Cards::Image) }
    original_documents_atom = page.atoms.find { |atom| atom.is_a?(Dummy::Atom::Contents::Documents) }
    clone_text_atom = clone.atoms.find { |atom| atom.is_a?(Dummy::Atom::Contents::Text) }
    clone_image_atom = clone.atoms.find { |atom| atom.is_a?(Dummy::Atom::Cards::Image) }
    clone_documents_atom = clone.atoms.find { |atom| atom.is_a?(Dummy::Atom::Contents::Documents) }

    assert_not_equal page.atoms.to_a, clone.atoms.to_a
    assert_equal page.cover, clone.cover
    assert_not_equal page.cover_placement, clone.cover_placement

    clone_text_atom.update!(content: "Změněný text")
    clone_image_atom.update!(title: "Změněný titulek", description: "Změněný popis", url_json: { href: "https://example2.com" })

    assert_equal original_documents_atom.documents.first, clone_documents_atom.documents.first
    assert_not_equal original_documents_atom.document_placements, clone_documents_atom.document_placements

    clone.update!(title: "Nový titulek",
                  perex: "Nový perex",
                  published_at: Time.current,
                  published: true)

    page.reload
    assert_equal original_attributes.without("created_at", "updated_at"), page.attributes.without("created_at", "updated_at")
    assert_equal "Původní text", original_text_atom.reload.content
    assert_not_equal original_text_atom.content, clone_text_atom.reload.content
    assert_equal image, original_image_atom.reload.cover
    assert_equal image, clone_image_atom.reload.cover
  end
end
