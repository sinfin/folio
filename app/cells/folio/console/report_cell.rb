# frozen_string_literal: true

class Folio::Console::ReportCell < Folio::ConsoleCell
  include SimpleForm::ActionViewExtensions::FormHelper
  include ActionView::Helpers::FormOptionsHelper

  include Folio::Console::Report::Dsl

  VALID_GROUP_BY = %w[ day week month ]
  PARAM_FOR_GROUP_BY = :report_by
  PARAM_FOR_DATE = :report_date
  MAX_DATA_POINT_COUNT = 53

  class_name "f-c-report", :loading?

  attr_accessor :date_time_from, :date_time_to, :group_by, :report_html, :date_spans, :date_labels

  def show
    set_date_time_attributes
    set_group_by_attribute
    respect_max_data_point_count_and_create_spans

    @report_html = ""
    instance_eval(&options[:block])

    render
  end

  def data
    {
      "controller" => "f-c-report",
      "f-c-report-loading-value" => loading? ? "true" : "false",
    }
  end

  def set_date_time_attributes
    if params[PARAM_FOR_DATE].present? &&
       params[PARAM_FOR_DATE].match?(/\d{1,2}\.\s?\d{1,2}\.\s?\d{4} - \d{1,2}\.\s?\d{1,2}\.\s?\d{4}/)
      from, to = params[PARAM_FOR_DATE].split(/ - /)

      if from.present?
        @date_time_from = DateTime.parse(from)
      end

      if to.present?
        @date_time_to = DateTime.parse(to)
      end
    end

    @date_time_from ||= Time.current.beginning_of_month
    @date_time_to ||= Time.current.end_of_month

    @date_time_from = @date_time_from.beginning_of_day
    @date_time_to = @date_time_to.end_of_day
  end

  def set_group_by_attribute
    @group_by = VALID_GROUP_BY.include?(params[PARAM_FOR_GROUP_BY]) ? params[PARAM_FOR_GROUP_BY] : VALID_GROUP_BY.first
  end

  def form(&block)
    opts = {
      url:,
      method: :get,
      html: {
        class: "f-c-report__form",
        "data-action" => "submit->f-c-report#onFormSubmit change->f-c-report#onFormChange",
        "data-f-c-report-target" => "form"
      },
    }

    simple_form_for("", opts, &block)
  end

  def url
    model[:url] || request.path
  end

  def group_by_input(f)
    f.input PARAM_FOR_GROUP_BY,
            collection: VALID_GROUP_BY.map { |key| [t(".group_by.#{key}"), key] },
            selected: group_by,
            input_html: {
              class: "f-c-report__header-group-by-input",
              "data-f-c-report-target" => "groupByInput"
            },
            wrapper_html: { class: "f-c-report__header-group-by-wrap" },
            label: false
  end

  def date_range_input(f)
    f.input PARAM_FOR_DATE,
            as: :date_range,
            input_html: {
              class: "f-c-report__header-date-input",
              value: "#{l(@date_time_from.to_date, format: :console_short)} - #{l(@date_time_to.to_date, format: :console_short)}",
              "data-f-c-report-target" => "dateInput"
            },
            wrapper_html: { class: "f-c-report__header-date-wrap" },
            label: false
  end

  def loading?
    params[PARAM_FOR_GROUP_BY].blank? || params[PARAM_FOR_DATE].blank? || params[:_ajax].blank?
  end

  def respect_max_data_point_count_and_create_spans
    if @date_time_to - @date_time_from > 4.years
      @date_time_from = @date_time_to - 4.years
    end

    diff_in_days = (@date_time_to - @date_time_from).to_i

    if @group_by == "day" && diff_in_days > MAX_DATA_POINT_COUNT
      @group_by = "week"
    end

    if @group_by == "week" && diff_in_days / 7.0 > MAX_DATA_POINT_COUNT
      @group_by = "month"
    end

    @date_spans = []
    @date_labels = []

    runner = @date_time_from

    case @group_by
    when "day"
      date_format = "%d.%m.%Y"
      date_increment = 1.day
    when "week"
      date_format = "%Y / %U"
      date_increment = 1.week
    when "month"
      date_format = "%B %Y"
      date_increment = 1.month
    end

    while runner < @date_time_to
      @date_spans << runner
      @date_labels << l(runner, format: date_format).capitalize
      runner += date_increment
    end
  end

  def chart_data
    @chart_data ||= {
      date_spans: @date_spans,
      date_labels: @date_labels,
    }
  end
end
