# frozen_string_literal: true

require "test_helper"

class Folio::Console::Ui::NotificationModalComponentTest < Folio::Console::ComponentTest
  def test_render
    render_inline(Folio::Console::Ui::NotificationModalComponent.new)

    assert_selector(".f-c-ui-notification-modal")
  end
end
