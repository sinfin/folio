# frozen_string_literal: true

class Folio::Report
  attr_accessor :date_time_from,
                :date_time_to,
                :group_by,
                :disabled_group_by_keys,
                :date_spans,
                :date_labels,
                :date_format,
                :date_increment

  def initialize(group_by:, date_time_from:, date_time_to:)
    @group_by = group_by
    @date_time_from = date_time_from
    @date_time_to = date_time_to
    respect_max_date_spans_count_and_create_spans
  end

  def self.max_date_spans_count
    366
  end

  def chart_data
    @chart_data ||= {
      date_spans: @date_spans,
      date_labels: @date_labels,
    }
  end

  def counts_per_span(scope:, condition_proc:)
    ary = scope.to_a

    total = []
    current = []
    added = []
    removed = []

    last = []
    init = true

    date_spans.each do |span_start|
      span_end = span_start + date_increment

      filtered = []

      ary.each do |record|
        if condition_proc.call(record, span_start, span_end)
          filtered << record.id if filtered.exclude?(record.id)
        end
      end

      if init
        init = false
        newly_added = 0
        newly_removed = 0
      else
        newly_added = (filtered - last).size
        newly_removed = -1 * (last - filtered).size
      end

      total << filtered.size
      current << filtered.size - newly_added
      added << newly_added
      removed << newly_removed

      last = filtered
    end

    { total:, current:, added:, removed: }
  end

  private
    def respect_max_date_spans_count_and_create_spans
      @disabled_group_by_keys = []

      @date_time_to = Time.current.to_datetime if @date_time_to > Time.current

      if @date_time_to - @date_time_from > 4.years
        @date_time_from = @date_time_to - 4.years
      end

      diff_in_days = (@date_time_to - @date_time_from).to_i
      diff_in_weeks = diff_in_days / 7.0
      diff_in_months = diff_in_days / (365.25 / 12)

      if diff_in_days > self.class.max_date_spans_count
        @disabled_group_by_keys << "day"
        @group_by = "week" if @group_by == "day"

        if diff_in_days / 7.0 > self.class.max_date_spans_count
          @disabled_group_by_keys << "week"
          @group_by = "month" if @group_by == "week"
        end
      elsif diff_in_months < 1
        @disabled_group_by_keys << "month"
        @group_by = "week" if @group_by == "month"

        if diff_in_weeks < 1
          @disabled_group_by_keys << "week"
          @group_by = "day" if @group_by == "week"
        end
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
