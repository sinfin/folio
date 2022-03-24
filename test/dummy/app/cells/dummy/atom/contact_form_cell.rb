# frozen_string_literal: true

class Dummy::Atom::ContactFormCell < ApplicationCell
  def form_cell
    cell("folio/leads/form",
         Folio::Lead.new(email: "@"),
         layout: {
           rows: [
             %i[name email phone],
             %w[note]
           ]
         },
         note_rows: 5,
         above_form: model.text.present? ? content_tag(:p, cstypo(model.text), class: "mb-g") : nil,
         under_form:)
  end

  def under_form
    content_tag(:div, cell("dummy/ui/disclaimer").show, class: "mt-g small")
  end
end
