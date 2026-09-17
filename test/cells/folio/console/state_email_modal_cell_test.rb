# frozen_string_literal: true

require "test_helper"

# An aasm event declared with `email_modal: true` lets the console user notify
# the record's e-mail address as part of the state change. The cell hands the
# modal everything it needs through the trigger's data attributes.
class Folio::Console::StateEmailModalCellTest < Folio::Console::CellTest
  class TestRecordWithEmailModal < Dummy::TestRecord
    include Folio::HasAasmStates

    aasm do
      state :submitted, initial: true, color: "red"
      state :handled, color: "green"

      event :to_handled do
        transitions from: :submitted, to: :handled
      end

      event :to_handled_with_email, email_modal: true do
        transitions from: :submitted, to: :handled
      end
    end

    def aasm_email_default_subject(_event)
      "Handled: #{title}"
    end

    def aasm_email_default_text(_event)
      "The record was handled."
    end
  end

  test "an email_modal event trigger carries the address, the model and the prefilled subject" do
    record = TestRecordWithEmailModal.create!(title: "Test record", email: "recipient@test.test")
    html = render_state(record)
    trigger = html.find(".f-c-state__state--trigger[data-event-name='to_handled_with_email']")

    assert_equal "true", trigger["data-aasm-email-modal"]
    assert_equal "recipient@test.test", trigger["data-email"]
    assert_equal TestRecordWithEmailModal.to_s, trigger["data-klass"]
    assert_equal record.id.to_s, trigger["data-id"]
    assert_equal "to_handled_with_email", trigger["data-event-name"]
    assert_equal "Handled: Test record", trigger["data-email-subject"]
    assert_equal "The record was handled.", trigger["data-email-text"]
    assert_includes trigger["data-url"], "aasm_event=to_handled_with_email"
  end

  test "a plain event trigger carries no email modal data" do
    record = TestRecordWithEmailModal.create!(title: "Test record", email: "recipient@test.test")
    html = render_state(record)
    trigger = html.find(".f-c-state__state--trigger[data-event-name='to_handled']")

    assert_nil trigger["data-aasm-email-modal"]
    assert_equal "to_handled", trigger["data-event-name"]
  end

  private
    def render_state(record)
      user = create(:folio_site_user_link, roles: [:administrator], site: @site).user
      Folio::Current.user = user

      user.stub(:can_now?, true) do
        cell("folio/console/state", record).(:show)
      end
    end
end
