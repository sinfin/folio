# frozen_string_literal: true

class Folio::Console::Report::StackedChartCell < Folio::ConsoleCell
  GRAPH_COLORS = {
    blue: "#4c84fd",
    green: "#589e92",
    red: "#f0655d",
  }

  def chart_model
    {
      type: "bar",
      data: {
        labels: options[:report].date_labels,
        datasets: model.map do |hash|
          {
            label: hash[:label],
            backgroundColor: GRAPH_COLORS[hash[:color]] || GRAPH_COLORS[:blue],
            data: hash[:values],
          }
        end
      },
      options: {
        scales: {
          y: { stacked: true, ticks: { precision: 0 } },
          x: { stacked: true },
        },
        animation: { duration: 0 },
      }
    }
  end
end
