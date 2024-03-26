# frozen_string_literal: true

class Dummy::Ui::ButtonComponent < ApplicationComponent
  def initialize(variant: "primary",
                 size: nil,
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
                 href: nil)
    @variant = variant
    @size = size
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
    @onclick = onclick
    @right_icon = right_icon
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
    else
      h[:type] = @type
    end

    h[:class] = "d-ui-button btn btn-#{@variant}"

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
      h[:class] += " d-ui-button--label"

      if @hide_label_on_mobile &&
        h[:class] += " d-ui-button--hide-label-on-mobile"
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

    h
  end

  def icon_height
    case @size
    when :sm
      15
    when :lg
      22
    else
      20
    end
  end
end
