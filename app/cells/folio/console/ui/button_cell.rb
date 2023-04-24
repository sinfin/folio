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

    h[:class] = "f-c-ui-button btn btn-#{model[:variant] || "primary"}"

    if model[:class]
      h[:class] += " #{model[:class]}"
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
    ]
  end
end
