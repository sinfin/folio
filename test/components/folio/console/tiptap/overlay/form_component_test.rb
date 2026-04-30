# frozen_string_literal: true

require "test_helper"

class Folio::Console::Tiptap::Overlay::FormComponentTest < Folio::Console::ComponentTest
  class ColorNode < Folio::Tiptap::Node
    tiptap_node structure: {
      accent_color: :color,
    }
  end

  def test_render
    with_controller_class(Folio::Console::PagesController) do
      with_request_url "/console/pages/new" do
        node = Dummy::Tiptap::Node::Card.new
        render_inline(Folio::Console::Tiptap::Overlay::FormComponent.new(node:))

        assert_selector(".f-c-tiptap-overlay-form")
      end
    end
  end

  def test_render_color_input
    with_controller_class(Folio::Console::PagesController) do
      with_request_url "/console/pages/new" do
        node = ColorNode.new(accent_color: "#ff00aa")
        render_inline(Folio::Console::Tiptap::Overlay::FormComponent.new(node:))

        assert_selector('input[type="color"][name="tiptap_node_attrs[data][accent_color]"][value="#ff00aa"]')
      end
    end
  end
end
