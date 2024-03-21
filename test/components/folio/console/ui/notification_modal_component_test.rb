# frozen_string_literal: true

require "test_helper"

class Folio::Console::Ui::NotificationModalComponentTest < Folio::Console::ComponentTest
  def test_render
    model = "hello"

    render_inline(Folio::Console::Ui::NotificationModalComponent.new(model:))

    assert_selector(".f-c-ui-notification-modal")
  end
end
