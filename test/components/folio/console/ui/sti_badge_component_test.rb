# frozen_string_literal: true

require "test_helper"

class Folio::Console::Ui::StiBadgeComponentTest < Folio::Console::ComponentTest
  def test_render
    record = create(:folio_page)

    render_inline(Folio::Console::Ui::StiBadgeComponent.new(record:))

    assert_selector(".f-c-ui-sti-badge")
    assert_text(record.class.model_name.human)
  end
end
