# frozen_string_literal: true

require "test_helper"

class Folio::Console::Api::SiteUserLinksControllerTest < Folio::Console::BaseControllerTest
  test "set_locked" do
    link = create(:folio_site_user_link, site: @site)
    assert_not link.locked?

    patch url_for([:set_locked, :console, :api, link, format: :json]), params: {
      site_user_link: {
        locked: true,
      }
    }

    assert_response :ok

    assert link.reload.locked?
  end
end
