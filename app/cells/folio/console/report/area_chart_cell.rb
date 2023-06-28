# frozen_string_literal: true

class Folio::Console::Report::AreaChartCell < Folio::ConsoleCell
  include ActionView::Helpers::NumberHelper

  def trend
    @trend ||= if model[:values].size > 1
      first = model[:values].first.to_f
      last = model[:values].last.to_f

      if first.zero?
        nil
      elsif last.zero?
        -100
      else
        (100 * (last - first) / first).round
      end
    end
  end

  def trend_class_name
    base = "f-c-report-area-chart__trend"

    if trend > 0
      "#{base} #{base}--positive"
    elsif trend < 0
      "#{base} #{base}--negative"
    else
      "text-muted"
    end
  end

  def chart_model
    {
      data: {
        datasets: [{
          borderColor: "#4C84FD",
          backgroundColor: "#E4F0FC",
          fill: true,
          label: model[:title],
          data: model[:values],
        }],
        labels: options[:report].date_labels,
      },
      type: :line,
      options: {
        layout: {
          autoPadding: false,
        },
        scales: {
          x: { display: false },
          y: { display: false },
        },
        plugins: {
          legend: {
            display: false,
          },
        },
        elements: {
          point: {
            pointStyle: false,
          },
        },
        animation: { duration: 0 },
      }
    }
  end
end
