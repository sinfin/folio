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

    if model[:atoms_previews]
      h[:class] += " f-c-ui-button--atoms-previews f-c-ui-button--atoms-previews-#{variant}"
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
    ]
  end

  def variant
    if model[:variant] == :medium_dark
      "medium-dark"
    else
      model[:variant] || "primary"
    end
  end
end
