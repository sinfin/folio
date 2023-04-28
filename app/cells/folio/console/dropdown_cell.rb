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
    model[:button_model].merge("aria-expanded" => "false",
                               "aria-haspopup" => "true",
                               "data-toggle" => "dropdown",
                               "class" => model[:button_model][:class] ? "#{model[:button_model][:class]} dropdown-toggle" : "dropdown-toggle",
                               "label" => model[:title])
  end
end
