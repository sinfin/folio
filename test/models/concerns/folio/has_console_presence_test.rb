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

  test "touch_console_presence! recovers from concurrent insert (RecordNotUnique)" do
    # Simulate the race condition:
    # 1. Pre-insert the presence row (as if a concurrent request already committed it).
    # 2. Build a new, unsaved presence object for the same (user, record) — this is what
    #    find_or_initialize_by would return in the race window before the concurrent INSERT.
    # 3. Stub save! on that object to raise RecordNotUnique (the unique index fires).
    # 4. Stub console_presences.find_or_initialize_by to return that unsaved object.
    # The rescue path must then update_all on the existing row and call touch_console_active!.

    attrs = { record_type: page.class.base_class.name, record_id: page.id }

    # The "concurrent winner" row — already in DB, stale updated_at
    Folio::ConsolePresence.create!(user: user, updated_at: 1.hour.ago, **attrs)

    # The "loser" object that find_or_initialize_by would have returned
    racing_presence = Folio::ConsolePresence.new(user: user, **attrs)

    # Stub find_or_initialize_by on the real association proxy
    assoc = user.console_presences
    assoc.stub :find_or_initialize_by, racing_presence do
      # Stub save! on the specific instance to raise the unique-index error
      racing_presence.stub :save!, -> { raise ActiveRecord::RecordNotUnique } do
        freeze_time do
          assert_nothing_raised { user.touch_console_presence!(page) }

          presences = Folio::ConsolePresence.where(user_id: user.id, **attrs)
          assert_equal 1, presences.count
          assert_in_delta Time.current, presences.first.updated_at, 1.second
        end
      end
    end

    assert_not_nil user.reload.console_active_at
  end
end
