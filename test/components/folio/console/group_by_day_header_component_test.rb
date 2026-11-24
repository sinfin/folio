# frozen_string_literal: true

require "test_helper"

class Folio::Console::GroupByDayHeaderComponentTest < Folio::Console::ComponentTest
  def test_render
    date = Time.zone.parse("2024-01-15 10:00:00")
    scope = Folio::Page.all

    render_inline(Folio::Console::GroupByDayHeaderComponent.new(
      scope:,
      date:,
      attribute: :created_at,
    ))

    assert_selector(".f-c-group-by-day")
    assert_selector(".f-c-group-by-day__date")
    assert_selector(".f-c-group-by-day__label")
  end

  def test_render_with_label_lambda
    date = Time.zone.parse("2024-01-15 10:00:00")
    scope = Folio::Page.all
    label_lambda = ->(count) { "Found #{count} items" }

    render_inline(Folio::Console::GroupByDayHeaderComponent.new(
      scope:,
      date:,
      attribute: :created_at,
      label_lambda:,
    ))

    assert_selector(".f-c-group-by-day")
  end

  def test_render_with_klass
    date = Time.zone.parse("2024-01-15 10:00:00")
    scope = Folio::Page.all

    render_inline(Folio::Console::GroupByDayHeaderComponent.new(
      scope:,
      date:,
      attribute: :created_at,
      before_label: "Before ",
      klass: Folio::Page,
      after_label: " after",
    ))

    assert_selector(".f-c-group-by-day")
  end

  def test_does_not_render_when_date_is_nil
    scope = Folio::Page.all

    result = render_inline(Folio::Console::GroupByDayHeaderComponent.new(
      scope:,
      date: nil,
      attribute: :created_at,
    ))

    assert_equal "", result.to_html.strip
  end
end
