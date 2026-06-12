# frozen_string_literal: true

require "test_helper"

class Folio::HasConsolePresenceTest < ActiveSupport::TestCase
  attr_reader :user, :page, :other_page

  def setup
    super
    @user = create(:folio_user)
    @page = create(:folio_page)
    @other_page = create(:folio_page)
  end

  test "touch_console_presence! creates a fresh presence row for the record" do
    user.touch_console_presence!(page)

    presence = Folio::ConsolePresence.for_record(page).find_by(user_id: user.id)
    assert presence
    assert_in_delta Time.current, presence.updated_at, 2.seconds
  end

  test "touch_console_presence! is idempotent per (user, record)" do
    user.touch_console_presence!(page)
    user.touch_console_presence!(page)

    assert_equal 1, Folio::ConsolePresence.for_record(page).where(user_id: user.id).count
  end

  test "touch_console_presence! also bumps console_active_at" do
    assert_nil user.reload.console_active_at
    user.touch_console_presence!(page)
    assert_not_nil user.reload.console_active_at
  end

  test "clear_console_presence! removes all of the user's presence rows" do
    user.touch_console_presence!(page)
    user.touch_console_presence!(other_page)

    user.clear_console_presence!

    assert_equal 0, Folio::ConsolePresence.where(user_id: user.id).count
  end

  test "touch_console_active! sets console_active_at without creating presence" do
    user.touch_console_active!

    assert_not_nil user.reload.console_active_at
    assert_equal 0, Folio::ConsolePresence.where(user_id: user.id).count
  end
end
