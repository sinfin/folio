# frozen_string_literal: true

class Dummy::Ui::PagyComponent < ApplicationComponent
  include Pagy::Frontend

  def initialize(pagy:)
    @pagy = pagy
  end

  def link
    @link ||= pagy_anchor(@pagy)
  end

  def build_link(item, label, aria: nil)
    link.call(item,
              label,
              aria_label: aria,
              classes: "d-ui-pagy__page-link")
  end

  def series_as_hashes
    @pagy.series.map do |item|
      h = { item: }

      case item
      when Integer # page link
        h[:link] = build_link(item, item)
        if item != 1 && item != @pagy.last && @pagy.page != item
          h[:class_name] = "d-ui-pagy__page--hide-on-mobile"

          if (@pagy.page - item).abs > 1
            h[:class_name] += " d-ui-pagy__page--hide-on-tablet"
          end
        end
      when String # current page
        h[:class_name] = "d-ui-pagy__page--current"
        h[:label] = item
      when :gap # page gap
        h[:class_name] = "d-ui-pagy__page--gap"
        h[:label] = "&hellip;"
      end

      h
    end
  end
end
