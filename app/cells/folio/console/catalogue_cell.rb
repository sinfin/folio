# frozen_string_literal: true

class Folio::Console::CatalogueCell < Folio::ConsoleCell
  include SimpleForm::ActionViewExtensions::FormHelper

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

    if model[:ancestry]
      @record, _children = model[:records].first
    else
      @record = model[:records].first
    end

    @header_html = ""
    instance_eval(&model[:block])
    @header_html
  end

  def record_html(rec)
    @header_html = nil

    @record = rec
    @record_html = ""
    instance_eval(&model[:block])
    @record_html
  end

  def rendering_header?
    !@header_html.nil?
  end

  def collection_actions
    return @collection_actions unless @collection_actions.nil?

    @collection_actions = if !model[:merge] && model[:collection_actions].present?
      model[:collection_actions]
    else
      false
    end
  end

  # every method call should use the attribute method
  def attribute(name = nil, value = nil, class_name: nil, spacey: false, compact: false, media_query: nil, skip_desktop_header: false, small: false, aligned: false, sanitize: false, hidden: false, &block)
    content = nil

    full_class_name = cell_class_name(name,
                                      class_name:,
                                      spacey:,
                                      small:,
                                      aligned:,
                                      compact:,
                                      media_query:,
                                      skip_desktop_header:)

    if rendering_header?
      @header_html += content_tag(:div,
                                  label_for(name, skip_desktop_header:, allow_sorting: true),
                                  class: full_class_name,
                                  hidden: hidden ? "" : nil)
    else
      if block_given?
        content = block.call(self.record)
      else
        content = value || record.send(name)
      end

      if sanitize
        content = sanitize_string(content)
      end

      value_div = content_tag(:div, content, class: "f-c-catalogue__cell-value")

      @record_html += content_tag(:div,
                                  "#{tbody_label_for(name)}#{value_div}",
                                  class: full_class_name,
                                  hidden: hidden ? "" : nil)
    end
  end

  def association(name, separator: ", ", small: false, link: false)
    assoc = record.send(name)

    handle_record = Proc.new do |record, link|
      label = record.to_label

      if link
        link_to(label, url_for([*link, record]))
      else
        label
      end
    end

    if assoc.is_a?(Enumerable)
      val = assoc.map do |record|
        handle_record.call(record, link)
      end.join(separator)
    elsif assoc.respond_to?(:to_label)
      val = handle_record.call(assoc, link)
    else
      val = nil
    end

    attribute(name, val, small:)
  end

  def type
    attribute(:type) { record.class.model_name.human }
  end

  def edit_link(attr = nil, sanitize: false, &block)
    resource_link(through_aware_console_url_for(record, action: :edit), attr, sanitize:, &block)
  end

  def show_link(attr = nil, sanitize: false, &block)
    resource_link(through_aware_console_url_for(record), attr, sanitize:, &block)
  end

  def date(attr = nil, small: false, alert_threshold: nil)
    attribute(attr, small:) do
      val = record.send(attr)
      cell("folio/console/catalogue/date", val, small:, alert_threshold:)
    end
  end

  def published_dates
    attribute(:published_dates, compact: true) do
      cell("folio/console/catalogue/published_dates", record)
    end
  end

  def locale_flag(locale_attr = :locale)
    attribute(locale_attr, compact: true, aligned: true, skip_desktop_header: true) do
      if record.send(locale_attr)
        cell("folio/console/ui/flag", record.send(locale_attr))
      end
    end
  end

  def featured_toggle(opts = {})
    toggle(:featured, opts)
  end

  def published_toggle(opts = {})
    if !rendering_header? && controller.cannot?(:publish, record)
      boolean(:published)
    else
      toggle(:published, opts)
    end
  end

  def toggle(attr, opts = {})
    attribute(attr, class_name: "toggle") do
      cell("folio/console/boolean_toggle", record, opts.merge(attribute: attr))
    end
  end

  def actions(*act)
    attribute(:actions, compact: true) do
      cell("folio/console/index/actions", record, actions: act)
    end
  end

  def audit_user
    attribute(:user, record.try(:audit).try(:user).try(:full_name))
  end

  def email(attr = :email, sanitize: false)
    attribute(attr, spacey: true) do
      e = record.public_send(attr)

      if sanitize
        e = sanitize_string(e)
      end

      if e.present?
        icon = mail_to(e, folio_icon(:mail_outline, height: 16))
        "#{e} #{icon}"
      end
    end
  end

  def state(active: true, spacey: false)
    attribute(:state, spacey:) do
      cell("folio/console/state", record, active:)
    end
  end

  def position_controls(opts = {})
    attribute(:position, class_name: "position-buttons") do
      cell("folio/console/index/position_buttons",
           record,
           opts.merge(ancestry: model[:ancestry]))
    end
  end

  def cover(options = {})
    attribute(:cover) do
      cell("folio/console/index/images", record, options.merge(cover: true))
    end
  end

  def boolean(name, &block)
    bool = if block_given?
      yield(record)
    else
      record.send(name)
    end

    attribute(name, I18n.t("folio.console.boolean.#{bool}"))
  end

  def id
    attribute(:id)
  end

  def color(name)
    attribute(nil,
              "",
              class_name: ["color-border", "color-border-#{name}"])
  end

  def private_attachment(name, type, opts = {})
    attribute(name, compact: true, aligned: true) do
      cell("folio/console/private_attachments/single_dropzone",
           record,
           opts.merge(name:, minimal: true, type:))
    end
  end

  def transportable_dropdown
    return unless ::Rails.application.config.folio_show_transportable_frontend
    return unless record.try(:transportable?)
    attribute(:transportable_dropdown, compact: true, skip_desktop_header: true) do
      cell("folio/console/transportable/dropdown", record)
    end
  end

  def console_notes
    attribute(:console_notes, compact: true, skip_desktop_header: true) do
      cell("folio/console/console_notes/catalogue_tooltip", record)
    end
  end

  private
    def resource_link(url_or_args, attr = nil, sanitize: false)
      attribute(attr, spacey: true) do
        if block_given?
          content = yield(record)
        elsif attr == :type
          content = record.class.model_name.human
        else
          content = record.public_send(attr) || ""
        end

        if sanitize
          content = sanitize_string(content)
        end

        url = if url_or_args.is_a?(String)
          url_or_args
        else
          controller.url_for(url_or_args)
        end

        link_to(content, url)
      end
    end

    def cell_class_name(attr = nil, class_name: "", spacey: false, compact: false, media_query: nil, skip_desktop_header: false, small: false, aligned: false)
      full = ""

      if rendering_header?
        full += " f-c-catalogue__label"
        base = "f-c-catalogue__header-cell"
      else
        base = "f-c-catalogue__cell"
      end

      if attr
        full += " #{base} #{base}--#{attr}"
      else
        full += " #{base}"
      end

      if class_name
        if class_name.is_a?(Array)
          class_name.each do |str|
            full += " #{base}--#{str}"
          end
        else
          full += " #{base}--#{class_name}"
        end
      end

      if small
        full += " #{base}--small"
      end

      if spacey
        full += " #{base}--spacey"
      end

      if compact
        full += " #{base}--compact"
      end

      if aligned
        full += " #{base}--aligned"
      end

      if skip_desktop_header
        full += " #{base}--skip-desktop-header"
      end

      if media_query
        full += " #{base}--media_query-#{media_query}"
      end

      full
    end

    def label_for(attr = nil, skip_desktop_header: false, allow_sorting: false)
      return "" if skip_desktop_header
      return nil if attr.nil?
      return @labels[attr] unless @labels[attr].nil?

      @labels[attr] ||= if %i[actions cover].include?(attr)
        ""
      else
        base = klass.human_attribute_name(attr)

        if allow_sorting && arrows = cell("folio/console/catalogue_sort_arrows",
                                          klass:,
                                          attr:).show
          content_tag(:span, "#{base} #{arrows}", class: "f-c-catalogue__label-with-arrows")
        else
          base
        end
      end
    end

    def tbody_label_for(attr)
      content_tag(:div,
                  label_for(attr),
                  class: "f-c-catalogue__label f-c-catalogue__cell-label")
    end

    def wrap_class_name
      cn = "f-c-catalogue"

      if model[:merge]
        cn += " f-c-catalogue--merge"
      end

      if collection_actions
        cn += " f-c-catalogue--collection-actions"
      end

      if model[:ancestry]
        cn += " f-c-catalogue--ancestry"
      end

      cn
    end

    def row_class_lambda
      return @row_class_lambda unless @row_class_lambda.nil?
      @row_class_lambda = model[:row_class_lambda] || false
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

          cell("folio/console/group_by_day_header",
               scope: model[:records],
               date:,
               attribute: model[:group_by_day],
               before_label: @before_lambda_label,
               label_lambda: @before_lambda_label_lambda,
               klass:).show.try(:html_safe)
        end
      else
        @before_lambda = false
      end
    end

    def after_lambda
      return @after_lambda unless @after_lambda.nil?
      @after_lambda = model[:after_lambda] || false
    end

    def render_ancestry_children(children, depth = 1)
      html = ""

      if children.present?
        children.each do |child, subchildren|
          class_name = "f-c-catalogue__row "\
                       "f-c-catalogue__row--ancestry-child "\
                       "f-c-catalogue__row--ancestry-depth-#{depth}"

          if row_class_lambda
            class_name += " #{row_class_lambda.call(child)}"
          end

          html += content_tag(:div,
                              record_html(child),
                              class: class_name,
                              "data-depth" => depth)

          html += render_ancestry_children(subchildren, depth + 1)
        end
      end

      html
    end

    def collection_action_for(action)
      opts = {
        class: "f-c-catalogue__collection-actions-bar-button f-c-catalogue__collection-actions-bar-button--#{action}}",
        label: t(".actions.#{action}"),
        variant: :secondary,
      }

      if %i[destroy discard undiscard].include?(action)
        opts[:type] = :submit

        if action == :destroy
          opts[:variant] = :danger
          opts[:icon] = :delete
          method = :delete
        elsif action == :discard
          opts[:icon] = :delete
          method = :delete
        else
          opts[:icon] = :arrow_u_left_top
          method = :post
        end

        opts["data-confirm"] = t("folio.console.confirmation")

        simple_form_for("",
                        url: url_for(["collection_#{action}".to_sym, :console, model[:klass]]),
                        method:,
                        html: { class: "f-c-catalogue__collection-actions-bar-form" }) do |f|
          cell("folio/console/ui/button", opts)
        end
      elsif action == :csv
        opts[:icon] = :download
        opts[:href] = url_for([:collection_csv, :console, model[:klass]])
        opts[:target] = "_blank"
        opts["data-url-base"] = opts[:href]

        cell("folio/console/ui/button", opts)
      else
        nil
      end
    end
end
