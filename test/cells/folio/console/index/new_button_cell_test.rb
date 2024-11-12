# frozen_string_literal: true

require "test_helper"

class Folio::Console::Index::NewButtonCellTest < Folio::Console::CellTest
  test "show if user can create model" do
    link = create(:folio_site_user_link, roles: ["administrator"])
    Folio::Current.user = link.user
    Folio::Current.site = link.site
    Folio::Current.reset_ability!
    assert Folio::Current.ability.can?(:new, Folio::Page)

    html = cell("folio/console/index/new_button", klass: Folio::Page).(:show)

    assert html.has_css?(".f-c-index-new-button")

    link2 = create(:folio_site_user_link, roles: [], site: link.site)
    Folio::Current.user = link2.user
    Folio::Current.reset_ability!
    assert_not Folio::Current.ability.can?(:new, Folio::Page)

    html = cell("folio/console/index/new_button", klass: Folio::Page).(:show)

    assert_not html.has_css?(".f-c-index-new-button")
  end
end
