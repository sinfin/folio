# frozen_string_literal: true

require "test_helper"

class Folio::Console::Ui::InPlaceInputComponentTest < Folio::Console::ComponentTest
  def test_render
    with_controller_class(Folio::Console::PagesController) do
      with_request_url "/console/pages" do
        attribute = :meta_title
        record = create(:folio_page)

        render_inline(Folio::Console::Ui::InPlaceInputComponent.new(attribute:, record:))

        assert_selector(".f-c-ui-in-place-input")
      end
    end
  end
end
