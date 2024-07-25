# frozen_string_literal: true

require "test_helper"

class Dummy::Ui::TopicsComponentTest < Folio::ComponentTest
  def test_render
    topics = [{ label: "foo", href: "foo" }]

    render_inline(Dummy::Ui::TopicsComponent.new(topics:))

    assert_selector(".d-ui-topics")
  end
end
