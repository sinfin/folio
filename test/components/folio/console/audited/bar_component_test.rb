# frozen_string_literal: true

require "test_helper"

class Folio::Console::Audited::BarComponentTest < Folio::Console::ComponentTest
  def test_render
    page = Audited.stub(:auditing_enabled, true) { create(:folio_page) }

    with_controller_class(Folio::Console::PagesController) do
      with_request_url "/console/pages" do
        render_inline(Folio::Console::Audited::BarComponent.new(audit: nil, record: page))
        assert_no_selector(".f-c-audited-bar")

        render_inline(Folio::Console::Audited::BarComponent.new(audit: page.audits.last, record: page))
        assert_selector(".f-c-audited-bar")
      end
    end
  end
end
