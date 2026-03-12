# frozen_string_literal: true

require "test_helper"

class Folio::Console::ConcurrentEditingTest < Folio::Console::BaseControllerTest
  attr_reader :alice, :bob, :page

  def setup
    super
    sign_out superadmin

    @alice = superadmin
    @bob = create(:folio_user, superadmin: true)
    @page = create(:folio_page)
    sign_in alice
  end

  test "one editing user: no warning, but stored record.updated_at" do
    get edit_console_page_url(page)

    assert_response :ok
    File.write("response.html", response.body)
    console_bar_class = ".f-c-current-users-console-url-bar"
    assert_select console_bar_class
    assert_select ("#{console_bar_class}[data-f-c-current-users-console-url-bar-record-updated-at-value=\"#{@page.updated_at.iso8601}\"]")
    assert_select "#{console_bar_class}[hidden=\"true\"]"
  end

  test "Alice make changes, Bob just watch" do
    # bob no changes
    # alice no changes
    # alice made changes
    # alice save changes
  end

  test "Alice make changes, Bob made changes without save" do
    # bob no changes
    # bob make changes
    # alice no changes
    # alice made changes
    # alice save changes
  end

  test "Alice make changes, Bob made changes and save" do
    # bob no changes
    # bob make changes
    # bob save changes
    # alice no changes
    # alice made changes
    # alice save changes
  end
end
