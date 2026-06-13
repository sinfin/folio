# frozen_string_literal: true

require "test_helper"

class Folio::Console::CurrentUsers::ConsoleUrlBarComponentTest < Folio::Console::ComponentTest
  def setup
    super
    @superadmin = create(:folio_user, :superadmin)
    Folio::Current.user = @superadmin
    Folio::Current.reset_ability!
  end

  def teardown
    Folio::Current.user = nil
    super
  end

  def test_renders_when_other_user_edits_the_record
    page = create(:folio_page)
    other_user = create(:folio_user, :superadmin)
    other_user.touch_console_presence!(page)

    render_bar(page)

    assert_selector(".f-c-current-users-console-url-bar")
    assert_selector("[data-f-c-current-users-console-url-bar-variant-value='other_user']")
  end

  def test_renders_presence_row_and_does_not_raise
    page = create(:folio_page)
    other_user = create(:folio_user, :superadmin)
    other_user.touch_console_presence!(page)

    render_bar(page)

    assert_selector(".f-c-current-users-console-url-bar")
    presence = Folio::ConsolePresence.for_record(page).where(user: other_user).first
    assert_not_nil presence
  end

  def test_renders_takeover_bar_without_crashing
    page = create(:folio_page)
    other_user = create(:folio_user, :superadmin)
    other_user.touch_console_presence!(page)

    # Create differing revisions so other_user_has_different_revision? returns true
    page.tiptap_revisions.create!(
      user: @superadmin,
      attribute_name: "tiptap_content",
      content: { "content" => "current user draft" },
    )
    page.tiptap_revisions.create!(
      user: other_user,
      attribute_name: "tiptap_content",
      content: { "content" => "other user draft" },
    )

    render_bar(page)

    assert_selector(".f-c-current-users-console-url-bar")
    assert_selector("[data-f-c-current-users-console-url-bar-variant-value='takeover']")
    # The takeover title uses other_presence.updated_at — must not raise
    presence = Folio::ConsolePresence.for_record(page).where(user: other_user).first
    I18n.with_locale(:cs) do
      assert_text I18n.l(presence.updated_at, format: :short)
    end
  end

  def test_does_not_render_without_other_user
    page = create(:folio_page)
    render_bar(page)
    assert_no_selector(".f-c-current-users-console-url-bar")
  end

  def test_does_not_render_when_other_presence_is_stale
    page = create(:folio_page)
    other_user = create(:folio_user, :superadmin)
    Folio::ConsolePresence.create!(user: other_user, record: page, updated_at: 10.minutes.ago)

    render_bar(page)
    assert_no_selector(".f-c-current-users-console-url-bar")
  end

  private
    def render_bar(record)
      with_controller_class(Folio::Console::BaseController) do
        with_request_url "/console/pages/#{record.id}/edit" do
          render_inline(Folio::Console::CurrentUsers::ConsoleUrlBarComponent.new(show: true, record:))
        end
      end
    end
end
