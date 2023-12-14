# frozen_string_literal: true

require "test_helper"

class Dummy::Atom::Images::OneAndTwoComponentTest < Folio::ComponentTest
  def test_render
    images = create_list(:folio_file_image, 3)

    atom = create_atom(Dummy::Atom::Images::OneAndTwo, images:)

    render_inline(Dummy::Atom::Images::OneAndTwoComponent.new(atom:))

    assert_selector(".d-atom-images-one-and-two")
  end
end
