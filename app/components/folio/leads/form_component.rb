# frozen_string_literal: true

class Folio::Leads::FormComponent < ApplicationComponent
  def initialize(lead: nil)
    @lead = lead || Folio::Lead.new
  end

  def form(&block)
    opts = {
      url: controller.folio.leads_path,
      html: { class: "f-leads-form__form", id: nil, data: stimulus_data(action: "onFormSubmit", target: "form") },
    }

    simple_form_for(@lead, opts, &block)
  end

  def data
    stimulus_controller("f-leads-form",
                        values: {
                          loading: false,
                          failure_message: t(".failure"),
                        })
  end

  def email_required?
    true
  end

  def note_required?
    true
  end
end
