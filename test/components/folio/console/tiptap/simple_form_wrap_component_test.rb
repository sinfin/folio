# frozen_string_literal: true

require "test_helper"

class Folio::Console::Tiptap::SimpleFormWrapComponentTest < Folio::Console::ComponentTest
  def test_render
    with_controller_class(Folio::Console::PagesController) do
      with_request_url "/console/pages/new" do
        simple_form_model = [:console, Folio::Page.new]

        render_inline(Folio::Console::Tiptap::SimpleFormWrapComponent.new(simple_form_model:))

        assert_selector(".f-c-tiptap-simple-form-wrap")
      end
    end
  end

  test "renders a read-only Tiptap input without modification controls" do
    with_controller_class(Folio::Console::PagesController) do
      with_request_url "/console/pages/new" do
        simple_form_model = [:console, Folio::Page.new]
        simple_form_options = {
          form_footer_options: { disable_modifications: true },
          tiptap_input_options: {
            tiptap_content: { readonly: true },
          },
        }

        render_inline(Folio::Console::Tiptap::SimpleFormWrapComponent.new(
          simple_form_model:,
          simple_form_options:,
        )) { "custom form fields" }

        assert_selector "[data-f-input-tiptap-readonly-value='true']"
        assert_no_selector "[data-test-id='submit-button']"
      end
    end
  end
end
