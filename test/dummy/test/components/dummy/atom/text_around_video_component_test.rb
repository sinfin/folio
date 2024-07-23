# frozen_string_literal: true

require "test_helper"

class Dummy::Atom::TextAroundVideoComponentTest < Folio::ComponentTest
  def test_render
    atom = create_atom(Dummy::Atom::TextAroundVideo, :video_cover, :content)

    render_inline(Dummy::Atom::TextAroundVideoComponent.new(atom:))

    assert_selector(".d-atom-text-around-video")
  end
end
