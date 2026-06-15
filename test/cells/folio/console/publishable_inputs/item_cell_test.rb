# frozen_string_literal: true

require "test_helper"

class Folio::Console::PublishableInputs::ItemCellTest < Folio::Console::CellTest
  class PublishableWithinRecord < Dummy::TestRecord
    include Folio::Publishable::Within

    def self.use_preview_tokens?
      false
    end
  end

  test "published within is date restricted with future start and blank end" do
    record = PublishableWithinRecord.new(published: true,
                                         published_from: 2.days.from_now,
                                         published_until: nil)

    html = render_publishable_item(record)

    assert html.has_css?(".f-c-publishable-inputs-item--date-restricted")
    assert_not html.has_css?(".f-c-publishable-inputs-item--active")
  end

  test "published within is date restricted with blank start and past end" do
    record = PublishableWithinRecord.new(published: true,
                                         published_from: nil,
                                         published_until: 2.days.ago)

    html = render_publishable_item(record)

    assert html.has_css?(".f-c-publishable-inputs-item--date-restricted")
    assert_not html.has_css?(".f-c-publishable-inputs-item--active")
  end

  test "published within is active with past start and blank end" do
    record = PublishableWithinRecord.new(published: true,
                                         published_from: 2.days.ago,
                                         published_until: nil)

    html = render_publishable_item(record)

    assert html.has_css?(".f-c-publishable-inputs-item--active")
    assert_not html.has_css?(".f-c-publishable-inputs-item--date-restricted")
  end

  private
    def render_publishable_item(record)
      html = nil

      controller.view_context.simple_form_for(record, url: "/") do |f|
        html = cell("folio/console/publishable_inputs/item",
                    f:,
                    field: :published).(:show)
      end

      html
    end
end
