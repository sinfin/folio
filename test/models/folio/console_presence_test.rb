# frozen_string_literal: true

require "test_helper"

class Folio::ConsolePresenceTest < ActiveSupport::TestCase
  attr_reader :user, :other_user, :page

  def setup
    super
    @user = create(:folio_user)
    @other_user = create(:folio_user)
    @page = create(:folio_page)
  end

  test "others_editing returns fresh presences of other users on the record" do
    Folio::ConsolePresence.create!(user: other_user, record: page, updated_at: Time.current)

    result = Folio::ConsolePresence.others_editing(page, except_user_id: user.id)

    assert_equal [other_user.id], result.map(&:user_id)
  end

  test "others_editing excludes the asking user" do
    Folio::ConsolePresence.create!(user: user, record: page, updated_at: Time.current)

    assert_empty Folio::ConsolePresence.others_editing(page, except_user_id: user.id)
  end

  test "others_editing excludes stale presences" do
    Folio::ConsolePresence.create!(user: other_user, record: page, updated_at: 10.minutes.ago)

    assert_empty Folio::ConsolePresence.others_editing(page, except_user_id: user.id)
  end

  test "others_editing matches STI records by base_class" do
    Folio::ConsolePresence.create!(user: other_user,
                                   record_type: page.class.base_class.name,
                                   record_id: page.id,
                                   updated_at: Time.current)

    assert_not_empty Folio::ConsolePresence.others_editing(page, except_user_id: user.id)
  end
end
