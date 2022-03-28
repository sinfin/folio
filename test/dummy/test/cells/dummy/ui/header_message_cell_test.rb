# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::HeaderMessageCellTest < Cell::TestCase
  test "show" do
    site = create_and_host_site
    assert_not site.header_message_published?
    html = cell("dummy/ui/header_message", site).(:show)
    assert_not html.has_css?(".d-ui-header-message")

    site.update!(header_message: "foo", header_message_published: true)
    assert site.header_message_published?
    html = cell("dummy/ui/header_message", site).(:show)
    assert html.has_css?(".d-ui-header-message")

    now = Time.zone.now

    site.update!(header_message: "foo",
                 header_message_published_from: now - 1.day,
                 header_message_published_until: now + 1.day)
    assert site.header_message_published?
    html = cell("dummy/ui/header_message", site).(:show)
    assert html.has_css?(".d-ui-header-message")

    site.update!(header_message_published_until: now - 1.day)
    assert_not site.header_message_published?
    html = cell("dummy/ui/header_message", site).(:show)
    assert_not html.has_css?(".d-ui-header-message")
  end
end
