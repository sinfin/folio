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
                 type: :button)
    @variant = variant
    @size = size
    @confirm = confirm
    @class_name = class_name
    @label = label
    @icon = icon
    @data = data
    @tag = tag
    @type = type
  end

  def tag
    h = {
      tag: @tag,
      data: @data,
    }

    if h[:href]
      h[:tag] ||= :a
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

    if @modal.present?
      h["data-bs-toggle"] = "modal"
      h["data-bs-target"] = @modal
    end

    h
  end

  def icon_height
    case @size
    when :sm
      16
    else
      24
    end
  end
end
