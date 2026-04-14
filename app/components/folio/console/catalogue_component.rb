# frozen_string_literal: true

class Folio::Console::CatalogueComponent < Folio::Console::ApplicationComponent
  include SimpleForm::ActionViewExtensions::FormHelper

  attr_reader :klass, :locals, :record

  delegate :through_aware_console_url_for,
           :safe_url_for,
           to: :controller

  def initialize(records:, block:, klass:, merge: nil, pagy: nil,
                 ancestry: nil, allow_sorting: true, js_data: nil,
                 collection_actions: nil, row_class_lambda: nil,
                 before_lambda: nil, after_lambda: nil,
                 group_by_day: nil, group_by_day_label_before: nil,
                 group_by_day_label_lambda: nil, new_button: nil,
                 types: nil, create_defaults_path: nil,
                 locals: {})
    @records = records
    @block = block
    @klass = klass
    @merge = merge
    @pagy = pagy
    @ancestry = ancestry
    @allow_sorting = allow_sorting
    @js_data = js_data
    @collection_actions_option = collection_actions
    @row_class_lambda_option = row_class_lambda
    @before_lambda_option = before_lambda
    @after_lambda_option = after_lambda
    @group_by_day = group_by_day
    @group_by_day_label_before = group_by_day_label_before
    @group_by_day_label_lambda = group_by_day_label_lambda
    @new_button = new_button
    @types = types
    @create_defaults_path = create_defaults_path
    @locals = locals.freeze
  end

  def ancestry?
    @ancestry.present?
  end

  def header_html
    return @header_html if @header_html

    if @ancestry
      @record, _children = @records.first
    else
      @record = @records.first
    end

    @header_html = ""
    instance_eval(&@block)
    @header_html
  end

  def record_html(rec, html_to_first_cell: nil)
    @header_html = nil

    @html_to_first_cell = html_to_first_cell
    @record = rec
    @record_html = ""
    instance_eval(&@block)
    @record_html
  end

  def rendering_header?
    !@header_html.nil?
  end

  def catalogue_data
    stimulus_lightbox.merge(boundaries_hash)
                     .merge(@js_data || {})
  end

  def collection_actions
    nil
  end

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
      allow_sorting = @allow_sorting
      @header_html += content_tag(:div,
                                  label_for(name, skip_desktop_header:, allow_sorting:),
                                  class: full_class_name,
                                  hidden: hidden ? "" : nil)
    else
      if block_given?
        content = block.call(record)
      else
        content = value || record.send(name)
      end

      if sanitize
        content = sanitize_string(content)
      end

      if @html_to_first_cell
        content = "#{@html_to_first_cell} #{content}"
        @html_to_first_cell = nil
      end

      value_div = content_tag(:div, content, class: "f-c-catalogue__cell-value")

      @record_html += content_tag(:div,
                                  "#{tbody_label_for(name)}#{value_div}",
                                  class: full_class_name,
                                  hidden: hidden ? "" : nil)
    end
  end

  def association(name, separator: ", ", small: false, link: false, minimal: false)
    assoc = record.send(name)

    handle_record = proc do |assoc_record, link_arg|
      label = assoc_record.to_label

      if minimal
        content_tag(:span, label, class: "f-c-catalogue__cell-value-minimal", title: label)
      elsif link_arg
        link_to(label, url_for([*link_arg, assoc_record]))
      else
        label
      end
    end

    val = if assoc.is_a?(Enumerable)
      assoc.map do |assoc_record|
        handle_record.call(assoc_record, link)
      end.join(minimal ? " " : separator)
    elsif assoc.respond_to?(:to_label)
      handle_record.call(assoc, link)
    end

    attribute(name, val, small:)
  end

  def type
    attribute(:type) { record.class.model_name.human }
  end

  def show_or_edit_link(attr = nil, sanitize: false, &block)
    if can_now?(:edit, record)
      true_edit_link(attr, sanitize:, &block)
    else
      show_link(attr, sanitize:, &block)
    end
  end

  def text_or_edit_link(attr = nil, sanitize: false, &block)
    if can_now?(:edit, record)
      true_edit_link(attr, sanitize:, &block)
    else
      attribute(attr, spacey: true)
    end
  end

  def true_edit_link(attr = nil, sanitize: false, &block)
    resource_link(through_aware_console_url_for(record, action: :edit), attr, sanitize:, &block)
  end

  def edit_link(attr = nil, sanitize: false, &block)
    show_or_edit_link(attr, sanitize:, &block)
  end

  def show_link(attr = nil, sanitize: false, &block)
    resource_link(through_aware_console_url_for(record), attr, sanitize:, &block)
  end

  def date(attr = nil, small: false, alert_threshold: nil, &block)
    attribute(attr, small:) do
      value = if block_given?
        yield(record)
      else
        record.send(attr)
      end

      render_catalogue_child(Folio::Console::Catalogue::DateComponent.new(value:,
                                                                          alert_threshold:))
    end
  end

  def published_dates
    attribute(:published_dates, compact: true) do
      render_catalogue_child(Folio::Console::Catalogue::PublishedDatesComponent.new(record:))
    end
  end

  def locale_flag(locale_attr = :locale)
    attribute(locale_attr, compact: true, aligned: true, skip_desktop_header: true) do
      if record.send(locale_attr)
        render_catalogue_child(Folio::Console::Ui::FlagComponent.new(locale: record.send(locale_attr)))
      end
    end
  end

  def featured_toggle(opts = {})
    if rendering_header? || can_now?(:feature, record)
      toggle(:featured, opts)
    else
      boolean(:featured)
    end
  end

  def published_toggle(opts = {})
    if rendering_header? || can_now?(:publish, record)
      toggle(:published, opts)
    else
      boolean(:published)
    end
  end

  def toggle(attr, opts = {})
    attribute(attr, class_name: "toggle", aligned: true) do
      render_catalogue_child(Folio::Console::Ui::BooleanToggleComponent.new(**opts.merge(record:,
                                                                                          attribute: attr)))
    end
  end

  def price(attr, price_opts = {}, &block)
    attribute(attr) do
      value = if block_given?
        yield(record)
      else
        record.send(attr)
      end

      folio_price(value, { nowrap: true }.merge(price_opts))
    end
  end

  def actions(*act)
    attribute(:actions, compact: true) do
      helpers.cell("folio/console/index/actions", record, actions: act)
    end
  end

  def audit_user
    attribute(:user, record.try(:audit).try(:user).try(:full_name))
  end

  def email(attr = :email, sanitize: false)
    attr_parts = attr.to_s.split(".")

    safe_attr = if attr_parts.size > 1
      attr_parts.last.to_sym
    else
      attr
    end

    attribute(safe_attr, spacey: true) do
      e = if attr_parts.size > 1
        runner = record

        attr_parts.each do |part|
          runner = runner.try(part)
        end

        runner
      else
        record.public_send(safe_attr)
      end

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
      helpers.cell("folio/console/state", record, active:)
    end
  end

  def position_controls(opts = {})
    return unless can_now?(:update, record)

    attribute(:position, class_name: "position-buttons") do
      helpers.cell("folio/console/index/position_buttons",
                   record,
                   opts.merge(ancestry: @ancestry))
    end
  end

  def cover(file: nil, href: false, lightbox: true)
    attribute(:cover) do
      href = case href
             when :edit
               through_aware_console_url_for(record, action: :edit)
             when :show
               through_aware_console_url_for(record)
             else
               href
      end

      render_catalogue_child(Folio::Console::Catalogue::CoverComponent.new(file: file || record.cover_placement.try(:file),
                                                                           href:,
                                                                           lightbox: href ? false : lightbox))
    end
  end

  def boolean(name, &block)
    bool = if block_given?
      yield(record)
    else
      record.send(name) || false
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
      helpers.cell("folio/console/private_attachments/single_dropzone",
                   record,
                   opts.merge(name:, minimal: true, type:))
    end
  end

  def transportable_dropdown
    return unless ::Rails.application.config.folio_show_transportable_frontend
    return unless record.try(:transportable?)
    return unless can_now?(:update, record)

    attribute(:transportable_dropdown, compact: true, skip_desktop_header: true) do
      helpers.cell("folio/console/transportable/dropdown", record)
    end
  end

  def console_notes
    attribute(:console_notes, compact: true, skip_desktop_header: true) do
      render_catalogue_child(Folio::Console::ConsoleNotes::CatalogueTooltipComponent.new(record:))
    end
  end

  def no_records_cell_options
    { klass: @klass, types: @types, new_button: @new_button, create_defaults_path: @create_defaults_path }
  end

  def sanitize_string(str)
    if str.present? && str.is_a?(String)
      ActionController::Base.helpers.sanitize(str, tags: [], attributes: [])
    else
      str
    end
  end

  def wrap_class_name
    cn = "f-c-catalogue"

    if @merge
      cn += " f-c-catalogue--merge"
    end

    if collection_actions
      cn += " f-c-catalogue--collection-actions"
    end

    if @ancestry
      cn += " f-c-catalogue--ancestry"
    end

    cn
  end

  def row_class_lambda
    return @row_class_lambda_memo unless @row_class_lambda_memo.nil?

    @row_class_lambda_memo = @row_class_lambda_option || false
  end

  def before_lambda
    return @before_lambda_memo unless @before_lambda_memo.nil?

    if @before_lambda_option
      @before_lambda_memo = @before_lambda_option
    elsif @group_by_day
      @before_lambda_label = @group_by_day_label_before
      @before_lambda_label_lambda = @group_by_day_label_lambda
      @before_lambda_memo = lambda do |rec, collection, i|
        date = rec.send(@group_by_day)
        day = date.try(:beginning_of_day)

        return if day.blank?

        prev_day = if i > 0
          collection[i - 1].send(@group_by_day).try(:beginning_of_day)
        end

        return if day == prev_day

        helpers.cell("folio/console/group_by_day_header",
                     scope: @records,
                     date:,
                     attribute: @group_by_day,
                     before_label: @before_lambda_label,
                     label_lambda: @before_lambda_label_lambda,
                     klass:).show.try(:html_safe)
      end
    else
      @before_lambda_memo = false
    end
  end

  def after_lambda
    return @after_lambda_memo unless @after_lambda_memo.nil?

    @after_lambda_memo = @after_lambda_option || false
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

        ancestry_icon = folio_icon(:subdirectory_arrow_right,
                                   class: "f-c-catalogue__ancestry-icon",
                                   height: 18)

        html += content_tag(:div,
                            record_html(child, html_to_first_cell: ancestry_icon),
                            class: class_name,
                            "data-depth" => depth)

        html += render_ancestry_children(subchildren, depth + 1)
      end
    end

    html
  end

  def collection_action_for(action)
    opts = {
      class_name: "f-c-catalogue__collection-actions-bar-button f-c-catalogue__collection-actions-bar-button--#{action}",
      label: I18n.t("folio.console.catalogue.actions.#{action}"),
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

      opts[:data] = { confirm: I18n.t("folio.console.confirmation") }

      simple_form_for("",
                      url: url_for(["collection_#{action}".to_sym, :console, @klass]),
                      method:,
                      html: { class: "f-c-catalogue__collection-actions-bar-form" }) do |_f|
        render_catalogue_child(Folio::Console::Ui::ButtonComponent.new(**opts))
      end
    elsif action == :csv
      href = url_for([:collection_csv, :console, @klass])
      opts[:icon] = :download
      opts[:href] = href
      opts[:target] = "_blank"
      opts[:data] = { url_base: href }

      render_catalogue_child(Folio::Console::Ui::ButtonComponent.new(**opts))
    end
  end

  private
    def render_catalogue_child(component)
      helpers.render(component)
    end

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

    def before_render
      @labels = {}
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

        sort_component = Folio::Console::CatalogueSortArrowsComponent.new(klass:, attr:)
        if allow_sorting && sort_component.render?
          arrows = render_catalogue_child(sort_component)
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

    def boundaries_hash
      return {} if boundary_positions.blank?

      {
        "f-c-catalogue-prev-boundary-id" => boundary_positions[:prev_id],
        "f-c-catalogue-prev-boundary-position" => boundary_positions[:prev_position],
        "f-c-catalogue-next-boundary-id" => boundary_positions[:next_id],
        "f-c-catalogue-next-boundary-position" => boundary_positions[:next_position],
      }
    end

    def boundary_positions
      return @boundary_positions if defined?(@boundary_positions)

      @boundary_positions = {}

      return @boundary_positions unless klass.try(:has_folio_positionable?)
      return @boundary_positions unless @pagy.present?
      return @boundary_positions if @records.blank?

      first_record = @records.first
      last_record = @records.last
      descending = klass.try(:positionable_descending?)

      scope = klass.ordered
      scope = scope.by_site(first_record.site) if klass.try(:has_belongs_to_site?) && first_record.try(:site)

      if descending
        prev = scope.where("position > ?", first_record.position).first
        nxt = scope.where("position < ?", last_record.position).last
      else
        prev = scope.where("position < ?", first_record.position).last
        nxt = scope.where("position > ?", last_record.position).first
      end

      @boundary_positions[:prev_id] = prev.id if prev
      @boundary_positions[:prev_position] = prev.position if prev
      @boundary_positions[:next_id] = nxt.id if nxt
      @boundary_positions[:next_position] = nxt.position if nxt

      @boundary_positions
    end
end
