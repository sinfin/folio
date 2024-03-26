# frozen_string_literal: true

class Folio::LeadsController < Folio::ApplicationController
  include Folio::RenderComponentJson

  def create
    lead = Folio::Lead.new(lead_params.merge(url: request.referrer))

    @lead = check_recaptcha_if_needed(lead)
    @lead.site = current_site

    success = @lead.save

    Folio::LeadMailer.notification_email(@lead).deliver_later if success

    respond_to do |format|
      format.html do
        redirect_back fallback_location: main_app.root_path,
                      flash: success ? { success: t(".success") } : { alert: t(".failure") }
      end

      format.json do
        component = Rails.application.config.folio_leads_from_component_class_name.constantize
        render_component_json(component.new(lead: @lead))
      end
    end
  end

  private
    def lead_params
      params.require(:lead)
            .permit(:name,
                    :email,
                    :phone,
                    :note)
    end

    def check_recaptcha_if_needed(lead)
      if ENV["RECAPTCHA_SITE_KEY"].present? &&
         ENV["RECAPTCHA_SECRET_KEY"].present?
        lead.verified_captcha = verify_recaptcha(model: lead)
      end

      lead
    end
end
