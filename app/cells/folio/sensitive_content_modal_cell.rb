# frozen_string_literal: true

class Folio::SensitiveContentModalCell < ApplicationCell
  CLASS_NAME_BASE = "f-sensitive-content-modal"
  CLASS_NAME = ".#{CLASS_NAME_BASE}"

  def show
    if ::Rails.application.config.folio_modal_cell_name || ui_modal_cell_name
      cell(::Rails.application.config.folio_modal_cell_name || ui_modal_cell_name,
           class: CLASS_NAME_BASE,
           body: render,
           header: t(".title"),
           primary: { label: t(".accept"), class: "f-sensitive-content-modal__accept" },
           secondary: { label: t(".cancel") })
    end
  rescue NameError
    # ui not initialized
  end

  def ui_modal_cell_name
    "#{::Rails.application.class.name.deconstantize.underscore}/ui/modal"
  end
end
