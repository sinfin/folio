# frozen_string_literal: true

class Folio::Console::Ui::ButtonComponent < Folio::Console::ApplicationComponent
  renders_one :left

  def initialize(variant: "primary",
                 size: nil,
                 icon_height: nil,
                 confirm: false,
                 class_name: nil,
                 label: nil,
                 hide_label_on_mobile: false,
                 modal: nil,
                 icon: nil,
                 right_icon: nil,
                 loader: false,
                 data: {},
                 tag: :button,
                 type: :button,
                 disabled: false,
                 onclick: nil,
                 href: nil,
                 rel: nil,
                 title: nil,
                 target: nil,
                 notification_modal: nil,
                 aria: nil,
                 dropzone: nil,
                 form_modal: nil,
                 form_modal_title: nil,
                 form_action: nil,
                 form_method: nil)
    @variant = variant == :medium_dark ? "medium-dark" : variant
    @size = size
    @icon_height = icon_height || default_icon_height
    @confirm = confirm
    @class_name = class_name
    @label = label
    @hide_label_on_mobile = hide_label_on_mobile
    @modal = modal
    @icon = icon
    @data = data
    @tag = tag
    @disabled = disabled
    @type = type
    @href = href
    @target = target
    @rel = rel
    @title = title
    @onclick = onclick
    @right_icon = right_icon
    @notification_modal = notification_modal
    @aria = aria
    @dropzone = dropzone # TODO dropzone
    @form_modal = form_modal
    @form_modal_title = form_modal_title
    @form_action = form_action
    @form_method = form_method
  end

  def tag
    h = {
      tag: @tag,
      data: @data,
      disabled: @disabled,
    }

    if @href
      h[:tag] = :a
      h[:href] = @href
      h[:target] = @target if @target
      h[:rel] = @rel if @rel
      h[:title] = @title if @title
    else
      h[:type] = @type
      h[:formaction] = @form_action if @form_action.present?
      h[:formmethod] = @form_method if @form_method.present?
    end

    h[:class] = "f-c-ui-button btn btn-#{@variant}"

    if @confirm
      h[:data][:confirm] = @confirm == true ? t("folio.confirmation") : @confirm
    end

    if @class_name
      h[:class] += " #{@class_name}"
    end

    if @size
      h[:class] += " btn-#{@size}"
    end

    if @label.present?
      h[:class] += " f-c-ui-button--label"

      if @hide_label_on_mobile &&
        h[:class] += " f-c-ui-button--hide-label-on-mobile"
      end
    end

    if @onclick
      h[:onclick] = @onclick
    end

    if @modal.present?
      h[:data] = stimulus_modal_toggle(@modal).merge({
        "toggle" => "modal",
        "target" => @modal,
        "bs-toggle" => "modal",
        "bs-target" => @modal,
      })
    end

    if @form_modal.present?
      h[:data].merge!(stimulus_console_form_modal_trigger(@form_modal, title: @form_modal_title))
    end

    if @notification_modal.present?
      if h[:data]["controller"]
        h[:data]["controller"] += " f-c-ui-notification-modal-trigger"
      else
        h[:data]["controller"] = "f-c-ui-notification-modal-trigger"
      end

      if h[:data]["action"]
        h[:data]["action"] += " f-c-ui-notification-modal-trigger#onClick"
      else
        h[:data]["action"] = "f-c-ui-notification-modal-trigger#onClick"
      end

      h[:data]["f-c-ui-notification-modal-trigger-data-value"] = @notification_modal.to_json
    end

    if @aria
      @aria.each do |key, value|
        h["aria-#{key}"] = value
      end
    end

    h
  end

  def default_icon_height
    case @size
    when :sm
      16
    else
      24
    end
  end
end
