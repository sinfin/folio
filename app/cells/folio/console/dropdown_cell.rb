# frozen_string_literal: true

class Folio::Console::DropdownCell < Folio::ConsoleCell
  def show
    render if links.present?
  end

  def links
    model[:links]
  end

  def menu_align
    model[:menu_align] || :right
  end

  def button_model
    base = model[:button_model] || {}

    base.merge(aria: { expanded: "false", haspopup: "true" },
               data: (base[:data] || {}).merge(bs_toggle: "dropdown"),
               class_name: base[:class_name] ? "#{base[:class_name]} dropdown-toggle" : "dropdown-toggle",
               label: model[:title])
  end
end
