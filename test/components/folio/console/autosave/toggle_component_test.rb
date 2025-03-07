# frozen_string_literal: true

require "test_helper"

class Folio::Console::Autosave::ToggleComponentTest < Folio::Console::ComponentTest
  def test_enabled
    with_controller_class(Folio::Console::PagesController) do
      with_request_url "/console/pages" do
        Rails.application.config.stub(:folio_pages_autosave, true) do
          record = create(:folio_page)

          render_inline(Folio::Console::Autosave::ToggleComponent.new(record:))

          assert_selector(".f-c-autosave-toggle")
        end
      end
    end
  end

  def test_disabled
    with_controller_class(Folio::Console::PagesController) do
      with_request_url "/console/pages" do
        Rails.application.config.stub(:folio_pages_autosave, false) do
          record = create(:folio_page)

          render_inline(Folio::Console::Autosave::ToggleComponent.new(record:))

          assert_no_selector(".f-c-autosave-toggle")
        end
      end
    end
  end
end
