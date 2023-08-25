# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::HeaderMessageComponentTest < Folio::ComponentTest
  def test_no_message
    site = create_and_host_site
    assert_not site.header_message_published?

    render_inline(Dummy::Ui::HeaderMessageComponent.new)
    assert_no_selector(".d-ui-header-message")
  end

  def test_message
    site = create_and_host_site(attributes: { header_message: "foo", header_message_published: true })
    assert site.header_message_published?

    render_inline(Dummy::Ui::HeaderMessageComponent.new)
    assert_selector(".d-ui-header-message")
  end

  def test_message_time
    site = create_and_host_site(attributes: {
      header_message: "foo",
      header_message_published: true,
      header_message_published_from: 2.days.ago,
      header_message_published_until: 2.days.from_now
    })
    assert site.header_message_published?

    render_inline(Dummy::Ui::HeaderMessageComponent.new)
    assert_selector(".d-ui-header-message")
  end

  def test_no_message_time
    site = create_and_host_site(attributes: {
      header_message_published: true,
      header_message_published_until: 2.days.ago
    })
    assert_not site.header_message_published?

    render_inline(Dummy::Ui::HeaderMessageComponent.new)
    assert_no_selector(".d-ui-header-message")
  end
end
