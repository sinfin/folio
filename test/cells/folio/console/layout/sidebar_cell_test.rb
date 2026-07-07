# frozen_string_literal: true

require "test_helper"

class Folio::Console::Layout::SidebarCellTest < Folio::Console::CellTest
  REQUEST_PATH = "/console/lorem/ipsum/dolor"

  test "only marks the most specific matching link as active" do
    create_and_host_site
    Folio::Current.user = create(:folio_user, :superadmin)

    with_sidebar_links([
      {
        links: [
          [
            { label: "Ipsum", path: "/console/lorem/ipsum" },
            { label: "Dolor", path: REQUEST_PATH },
          ],
        ],
      },
    ]) do
      html = cell("folio/console/layout/sidebar", nil).(:show)
      active_links = html.all(".f-c-layout-sidebar__a--active")

      assert_equal 1, active_links.size
      assert_equal "Dolor", active_links.first.text
    end
  end

  private
    def controller
      @controller ||= super.tap do |controller|
        controller.request.path = REQUEST_PATH
        controller.request.host = "lorem.test"
      end
    end

    def with_sidebar_links(link_groups)
      previous = ::Rails.application.config.folio_console_sidebar_link_class_names
      ::Rails.application.config.folio_console_sidebar_link_class_names = link_groups
      yield
    ensure
      ::Rails.application.config.folio_console_sidebar_link_class_names = previous
    end
end
