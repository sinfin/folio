# frozen_string_literal: true

class Folio::Console::CatalogueCell < Folio::ConsoleCell
  include Folio::Console::FlagHelper

  attr_reader :record

  def show
    @labels = {}
    render
  end

  def klass
    @klass ||= model[:klass]
  end

  def header_html
    return @header_html if @header_html
    @record = model[:records].first
    @header_html = ''
    instance_eval(&model[:block])
    @header_html
  end

  def record_html(rec)
    @header_html = nil

    @record = rec
    @record_html = ''
    instance_eval(&model[:block])
    @record_html
  end

  def rendering_header?
    !@header_html.nil?
  end

  # every method call should use the attribute method
  def attribute(name = nil, value = nil, class_name: nil, spacey: false, &block)
    content = nil

    if rendering_header?
      @header_html += content_tag(:div,
                                  label_for(name),
                                  class: cell_class_name(name, class_name: class_name, spacey: spacey))
    else
      if block_given?
        content = block.call(self.record)
      else
        content = value || record.send(name)
      end

      value_div = content_tag(:div, content, class: 'f-c-catalogue__cell-value')

      @record_html += content_tag(:div,
                                  "#{tbody_label_for(name)}#{value_div}",
                                  class: cell_class_name(name, class_name: class_name, spacey: spacey))
    end
  end

  def association(name, separator: ', ')
    assoc = record.send(name)

    if assoc.is_a?(Enumerable)
      val = assoc.map(&:to_label).join(separator)
    else
      val = assoc.to_label
    end

    attribute(name, val)
  end

  def type
    attribute(:type, record.class.model_name.human)
  end

  def edit_link(attr = nil, &block)
    resource_link([:edit, :console, record], attr, &block)
  end

  def show_link(attr = nil, &block)
    resource_link([:console, record], attr, &block)
  end

  def date(attr = nil)
    val = record.send(attr)
    val = l(val, format: :short) if val.present?
    attribute(attr, val)
  end

  def locale_flag
    attribute(:locale) do
      country_flag(record.locale) if record.locale
    end
  end

  def featured_toggle
    toggle(:featured)
  end

  def published_toggle
    toggle(:published)
  end

  def toggle(attr)
    attribute(attr, class_name: 'toggle') do
      cell('folio/console/boolean_toggle', record, attribute: attr)
    end
  end

  def actions(*act)
    attribute(:actions) do
      cell('folio/console/index/actions', record, actions: act)
    end
  end

  def audit_user
    attribute(:user, record.try(:audit).try(:user).try(:full_name))
  end

  def email(attr = :email)
    attribute(attr, spacey: true) do
      e = record.public_send(attr)
      icon = mail_to(e, '', class: 'fa fa--small ml-1 fa-envelope')
      "#{e} #{icon}"
    end
  end

  def state(active: true, spacey: false)
    attribute(:state, spacey: spacey) do
      cell('folio/console/state', record, active: active)
    end
  end

  def position_controls(opts = {})
    attribute(:position, class_name: 'position-buttons') do
      cell('folio/console/index/position_buttons', record, opts)
    end
  end

  def cover
    attribute(:cover) do
      cell('folio/console/index/images', record, cover: true)
    end
  end

  def boolean(name)
    attribute(name, I18n.t("folio.console.boolean.#{record.send(name)}"))
  end

  private
    def resource_link(url_for_args, attr = nill)
      attribute(attr, spacey: true) do
        if block_given?
          content = yield(record)
        elsif attr == :type
          content = record.class.model_name.human
        else
          content = record.public_send(attr)
        end

        url = controller.url_for(url_for_args)
        link_to(content, url)
      end
    end

    def cell_class_name(attr = nil, class_name: '', spacey: false)
      full = ''

      if rendering_header?
        full += ' f-c-catalogue__label'
        base = 'f-c-catalogue__header-cell'
      else
        base = 'f-c-catalogue__cell'
      end

      if attr
        full += " #{base} #{base}--#{attr}"
      else
        full += " #{base}"
      end

      if class_name
        full += " #{base}--#{class_name}"
      end

      if spacey
        full += " #{base}--spacey"
      end

      full
    end

    def label_for(attr = nil)
      return nil if attr.nil?
      return @labels[attr] unless @labels[attr].nil?

      @labels[attr] ||= begin
        if %i[actions cover].include?(attr)
          ''
        else
          klass.human_attribute_name(attr)
        end
      end
    end

    def tbody_label_for(attr)
      content_tag(:div,
                  label_for(attr),
                  class: 'f-c-catalogue__label f-c-catalogue__cell-label')
    end

    def wrap_class_name
      if model[:merge]
        'f-c-catalogue--merge'
      end
    end

    def before_lambda
      return @before_lambda unless @before_lambda.nil?

      if model[:before_lambda]
        @before_lambda = model[:before_lambda]
      elsif model[:group_by_day]
        @before_lambda_label = model[:group_by_day_label_before]
        @before_lambda_label_lambda = model[:group_by_day_label_lambda]
        @before_lambda = -> (rec, collection, i) do
          date = rec.send(model[:group_by_day])
          day = date.try(:beginning_of_day)

          return if day.blank?

          if i > 0
            prev_day = collection[i - 1].send(model[:group_by_day]).try(:beginning_of_day)
          else
            prev_day = nil
          end

          return if day == prev_day

          cell('folio/console/group_by_day_header',
               scope: model[:records],
               date: date,
               attribute: model[:group_by_day],
               before_label: @before_lambda_label,
               label_lambda: @before_lambda_label_lambda,
               klass: klass).show.try(:html_safe)
        end
      else
        @before_lambda = false
      end
    end

    def after_lambda
      return @after_lambda unless @after_lambda.nil?
      @after_lambda = model[:after_lambda] || false
    end
end
