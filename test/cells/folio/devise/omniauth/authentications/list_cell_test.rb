# frozen_string_literal: true

require "test_helper"

class Folio::Devise::Omniauth::Authentications::ListCellTest < Cell::TestCase
  test "show" do
    html = cell("folio/devise/omniauth/authentications/list",
                create(:folio_user)).(:show)
    assert html.has_css?(".f-devise-omniauth-authentications-list")
  end
end
