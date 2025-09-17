# frozen_string_literal: true

class Folio::Leads::FormComponent < ApplicationComponent
  include Folio::ComponentSessionHelper

  def initialize(lead: nil)
    @lead = lead || Folio::Lead.new
  end

  def before_render
    # This component requires session for CSRF and form functionality
    require_session_for_component!("lead_form_csrf_and_flash")
  end

  def form(&block)
    opts = {
      url: controller.folio.leads_path,
      html: { class: "f-leads-form__form", id: nil, data: stimulus_data(action: "onFormSubmit", target: "form") },
    }

    helpers.simple_form_for(@lead, opts, &block)
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
