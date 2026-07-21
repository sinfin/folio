# frozen_string_literal: true

require "test_helper"

class TiptapInputTest < Folio::Console::CellTest
  test "serializes optional opaque editor context on the input wrapper" do
    node = ::Capybara.string(render_tiptap_input(editor_context: { scope_id: 123 }))

    assert node.has_css?("[data-f-input-tiptap-editor-context-json-value='{" \
                         "\"scope_id\":123}']")
  end

  test "omits blank editor context from the input wrapper" do
    node = ::Capybara.string(render_tiptap_input(editor_context: {}))

    assert_not node.has_css?("[data-f-input-tiptap-editor-context-json-value]")
  end

  test "passes an explicit read-only state to the editor" do
    node = ::Capybara.string(render_tiptap_input(readonly: true))

    assert node.has_css?("[data-f-input-tiptap-readonly-value='true']")
  end

  test "exposes the current user's mobile_first preference as the responsive-preview default" do
    Folio::Current.user = create(:folio_user, console_preferences: { "mobile_first" => true })

    node = ::Capybara.string(render_tiptap_input)

    assert node.has_css?("[data-f-input-tiptap-default-responsive-preview-value='true']")
  end

  test "omits the responsive-preview default when the user has no mobile_first preference" do
    Folio::Current.user = create(:folio_user)

    node = ::Capybara.string(render_tiptap_input)

    assert_not node.has_css?("[data-f-input-tiptap-default-responsive-preview-value]")
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
