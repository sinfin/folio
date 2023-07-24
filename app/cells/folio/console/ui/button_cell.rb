# frozen_string_literal: true

class Folio::Console::Ui::ButtonCell < Folio::ConsoleCell
  def tag
    h = model.without(*blacklist)

    if h[:href]
      h[:tag] ||= :a
    else
      h[:tag] ||= :button
      h[:type] ||= :button
    end

    h[:class] = "f-c-ui-button btn btn-#{variant}"

    if model[:confirm]
      h["data-confirm"] = t("folio.console.confirmation")
    end

    if model[:class]
      h[:class] += " #{model[:class]}"
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
      h["data-bs-toggle"] = "modal"
      h["data-bs-target"] = model[:modal]
    end

    if model[:notification_modal].present?
      if h["data-controller"]
        h["data-controller"] += " f-c-ui-notification-modal-trigger"
      else
        h["data-controller"] =  "f-c-ui-notification-modal-trigger"
      end

      if h["data-action"]
        h["data-action"] += " f-c-ui-notification-modal-trigger#onClick"
      else
        h["data-action"] =  "f-c-ui-notification-modal-trigger#onClick"
      end

      h["data-f-c-ui-notification-modal-trigger-data-value"] = model[:notification_modal].to_json
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
