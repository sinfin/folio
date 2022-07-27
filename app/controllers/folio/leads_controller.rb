# frozen_string_literal: true

class Folio::LeadsController < Folio::ApplicationController
  REMEMBER_OPTION_KEYS = [
    :note,
    :message,
    :name,
    :note_label,
    :note_rows,
    :layout,
    :next_to_submit,
    :above_form,
    :under_form,
  ]

  def create
    lead = Folio::Lead.new(lead_params.merge(url: request.referrer))

    @lead = check_recaptcha_if_needed(lead)

    if !Rails.application.config.folio_site_is_a_singleton
      @lead.site = current_site
    end

    success = @lead.save

    Folio::LeadMailer.notification_email(@lead).deliver_later if success

    render html: cell("folio/leads/form", @lead, cell_options_params)
  end

  private
    def lead_params
      params.require(:lead).permit(:name,
                                   :email,
                                   :phone,
                                   :note,
                                   :additional_data).tap do |obj|
        if obj[:additional_data].present?
          obj[:additional_data] = JSON.parse(obj[:additional_data])
        else
          obj[:additional_data] = nil
        end
      end
    end

    def cell_options_params
      cell_options = params[:cell_options]
      if cell_options
        cell_options.permit(*REMEMBER_OPTION_KEYS)
      else
        {}
      end
    end

    def check_recaptcha_if_needed(lead)
      if ENV["RECAPTCHA_SITE_KEY"].present? &&
         ENV["RECAPTCHA_SECRET_KEY"].present?
        lead.verified_captcha = verify_recaptcha(model: lead)
      end

      lead
    end
end
