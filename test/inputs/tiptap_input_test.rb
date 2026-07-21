# frozen_string_literal: true

require "test_helper"

class TiptapInputTest < Folio::Console::CellTest
  test "passes an explicit read-only state to the editor" do
    node = ::Capybara.string(render_tiptap_input(readonly: true))

    assert node.has_css?("[data-f-input-tiptap-readonly-value='true']")
  end

  private
    def render_tiptap_input(**options)
      html = nil

      controller.view_context.simple_form_for("", url: "/", method: :get) do |f|
        html = f.input(:tiptap_json,
                       as: :tiptap,
                       block: true,
                       **options,
                       input_html: { value: '{"tiptap_content":{"type":"doc","content":[]}}' })
      end

      html
    end
end
