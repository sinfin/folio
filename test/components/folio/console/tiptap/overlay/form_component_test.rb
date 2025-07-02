# frozen_string_literal: true

require "test_helper"

class Folio::Console::Tiptap::Overlay::FormComponentTest < Folio::Console::ComponentTest
  def test_render
    with_controller_class(Folio::Console::PagesController) do
      with_request_url "/console/pages/new" do
        node = Dummy::Tiptap::Node::Card.new
        render_inline(Folio::Console::Tiptap::Overlay::FormComponent.new(node:))

        assert_selector(".f-c-tiptap-overlay-form")
      end
    end
  end
end
