# frozen_string_literal: true

class Folio::Console::Transportable::DropdownCell < Folio::ConsoleCell
  def links
    if model.try(:id)
      [
        { title: t(".in"), url: controller.folio.in_console_transport_path(model.class, model.id) },
        { title: t(".out"), url: controller.folio.out_console_transport_path(model.class, model.id) },
      ]
    else
      [
        { title: t(".in_new"), url: controller.folio.in_console_transport_path },
      ]
    end
  end

  def title
    content_tag(:span, "more_vert", class: "mi f-c-transportable-dropdown__ico")
  end
end
