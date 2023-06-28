# frozen_string_literal: true

class Folio::Report
  attr_accessor :date_time_from,
                :date_time_to,
                :group_by,
                :date_spans,
                :date_labels,
                :date_format,
                :date_increment

  def initialize(group_by:, date_time_to:, date_time_from:)
    @group_by = group_by
    @date_time_to = date_time_to
    @date_time_from = date_time_from
    respect_max_data_point_count_and_create_spans
  end

  def self.max_data_point_count
    53
  end

  def chart_data
    @chart_data ||= {
      date_spans: @date_spans,
      date_labels: @date_labels,
    }
  end

  private
    def respect_max_data_point_count_and_create_spans
      @date_time_to = Time.current.to_datetime if @date_time_to > Time.current

      if @date_time_to - @date_time_from > 4.years
        @date_time_from = @date_time_to - 4.years
      end

      diff_in_days = (@date_time_to - @date_time_from).to_i

      if @group_by == "day" && diff_in_days > self.class.max_data_point_count
        @group_by = "week"
      end

      if @group_by == "week" && diff_in_days / 7.0 > self.class.max_data_point_count
        @group_by = "month"
      end

      @date_spans = []
      @date_labels = []

      runner = @date_time_from

      case @group_by
      when "day"
        @date_format = "%d.%m.%Y"
        @date_increment = 1.day
      when "week"
        @date_format = "%Y / %U"
        @date_increment = 1.week
      when "month"
        @date_format = "%B %Y"
        @date_increment = 1.month
      end

      while runner < @date_time_to
        @date_spans << runner
        @date_labels << I18n.l(runner, format: @date_format).capitalize
        runner += @date_increment
      end
    end
end
