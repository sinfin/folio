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
end
