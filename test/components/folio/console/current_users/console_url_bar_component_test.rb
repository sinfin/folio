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

  def test_does_not_render_without_other_user_at_url
    render_bar

    assert_no_selector(".f-c-current-users-console-url-bar")
  end

  def test_renders_when_other_user_is_at_url
    other_user = create(:folio_user, :superadmin)
    other_user.update_console_url!("http://test.host/console/pages/1/edit")

    render_bar

    assert_selector(".f-c-current-users-console-url-bar")
    assert_selector("[data-f-c-current-users-console-url-bar-variant-value='other_user']")
  end

  def test_does_not_render_when_other_user_is_stale_at_url
    other_user = create(:folio_user, :superadmin)
    other_user.update_columns(console_url: "http://test.host/console/pages/1/edit",
                              console_url_updated_at: 10.minutes.ago)

    render_bar

    assert_no_selector(".f-c-current-users-console-url-bar")
  end

  private
    def render_bar
      with_controller_class(Folio::Console::BaseController) do
        with_request_url "/console/pages/1/edit" do
          render_inline(Folio::Console::CurrentUsers::ConsoleUrlBarComponent.new(show: true))
        end
      end
    end
end
