# frozen_string_literal: true

class Folio::Console::ReportCell < Folio::ConsoleCell
  include SimpleForm::ActionViewExtensions::FormHelper
  include ActionView::Helpers::FormOptionsHelper

  include Folio::Console::Report::Dsl

  VALID_GROUP_BY = %w[ day week month ]
  PARAM_FOR_GROUP_BY = :report_by
  PARAM_FOR_DATE = :report_date

  class_name "f-c-report", :loading?

  attr_accessor :report_html, :report

  def show
    @report = report_klass.new(**attributes_for_report)

    @report_html = ""
    instance_eval(&options[:block])

    render
  end

  def report_klass
    "#{::Rails.application.class.to_s.deconstantize}::Report".safe_constantize || Folio::Report
  end

  def data
    {
      "controller" => "f-c-report",
      "f-c-report-loading-value" => loading? ? "true" : "false",
    }
  end

  def attributes_for_report
    h = {
      group_by: VALID_GROUP_BY.include?(params[PARAM_FOR_GROUP_BY]) ? params[PARAM_FOR_GROUP_BY] : VALID_GROUP_BY.first
    }

    if params[PARAM_FOR_DATE].present? &&
       params[PARAM_FOR_DATE].match?(/\d{1,2}\.\s?\d{1,2}\.\s?\d{4} - \d{1,2}\.\s?\d{1,2}\.\s?\d{4}/)
      from, to = params[PARAM_FOR_DATE].split(/ - /)

      if from.present?
        h[:date_time_from] = DateTime.parse(from)
      end

      if to.present?
        h[:date_time_to] = DateTime.parse(to)
      end
    end

    h[:date_time_from] ||= Time.current.to_datetime.beginning_of_month
    h[:date_time_to] ||= Time.current.to_datetime.end_of_month

    h[:date_time_from] = h[:date_time_from].beginning_of_day
    h[:date_time_to] = h[:date_time_to].end_of_day

    h
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
            selected: report.group_by,
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
              value: "#{l(report.date_time_from.to_date, format: :console_short)} - #{l(report.date_time_to.to_date, format: :console_short)}",
              "data-f-c-report-target" => "dateInput"
            },
            wrapper_html: { class: "f-c-report__header-date-wrap" },
            label: false
  end

  def loading?
    params[PARAM_FOR_GROUP_BY].blank? || params[PARAM_FOR_DATE].blank? || params[:_ajax].blank?
  end
end
