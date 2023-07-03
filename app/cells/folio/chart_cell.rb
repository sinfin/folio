# frozen_string_literal: true

class Folio::ChartCell < ApplicationCell
  class_name "f-chart", :overlay, :border_bottom_radius

  def data
    {
      "controller" => "f-chart",
      "chart" => chart_hash.to_json,
      "error" => t(".js_load_error"),
    }
  end

  def chart_hash
    model
  end
end
