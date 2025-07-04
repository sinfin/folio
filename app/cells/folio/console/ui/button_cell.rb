# frozen_string_literal: true

class Folio::Console::Ui::ButtonCell < Folio::ConsoleCell
  def tag
    h = model.without(*blacklist)

    if h[:href]
      h[:tag] ||= :a
    elsif h[:tag].nil?
      h[:tag] ||= :button
      h[:type] ||= :button
    end

    h[:class] = "f-c-ui-button btn btn-#{variant}"

    h[:data] = model[:data] || {}

    if model[:confirm]
      if model[:confirm].is_a?(String)
        h[:data]["confirm"] = model[:confirm]
      else
        h[:data]["confirm"] = t("folio.console.confirmation")
      end
    end

    if model[:method]
      h[:data]["method"] = model[:method]
    end

    if model[:disabled]
      h[:disabled] = true
      h[:class] += " disabled f-c-ui-button--disabled"
    end

    if model[:dropzone]
      h[:class] += " f-c-ui-button--dropzone"
    end

    if model[:class]
      h[:class] += " #{model[:class]}"
    end

    if model[:class_name]
      h[:class] += " #{model[:class_name]}"
    end

    if model[:size]
      h[:class] += " btn-#{model[:size]}"
    end

    if model[:label].present?
      h[:class] += " f-c-ui-button--label"

      if model[:hide_label_on_mobile] &&
        h[:class] += " f-c-ui-button--hide-label-on-mobile"
      end
    end

    if model[:modal].present?
      h[:data] = stimulus_merge(h[:data], stimulus_modal_toggle(model[:modal]))
    end

    if model[:form_modal].present?
      h[:data] = stimulus_merge(h[:data], stimulus_console_form_modal_trigger(model[:form_modal], title: model[:form_modal_title]))
    end

    if model[:notification_modal].present?
      h[:data] = stimulus_merge(h[:data], stimulus_controller("f-c-ui-notification-modal-trigger",
                                                              inline: true,
                                                              action: {
                                                                "click" => "onClick"
                                                              },
                                                              values: {
                                                                data: model[:notification_modal].to_json
                                                              }))
    end

    h
  end

  def blacklist
    %i[
      label
      icon
      right_icon
      class
      variant
      confirm
      method
      modal
      size
      notification_modal
    ]
  end

  def variant
    if model[:variant] == :medium_dark
      "medium-dark"
    else
      model[:variant] || "primary"
    end
  end

  def icon_height
    case model[:size]
    when :sm
      16
    else
      24
    end
  end
end
