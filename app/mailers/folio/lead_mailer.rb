# frozen_string_literal: true

class Folio::LeadMailer < Folio::ApplicationMailer
  def notification_email(lead)
    email_template_mail(
      FOLIO_LEAD_ID: lead.id,
      FOLIO_LEAD_EMAIL: lead.email,
      FOLIO_LEAD_PHONE: lead.phone,
      FOLIO_LEAD_NOTE: lead.note,
      FOLIO_LEAD_CREATED_AT: lead.created_at ? l(lead.created_at, format: :short) : "",
      FOLIO_LEAD_NAME: lead.name,
      FOLIO_LEAD_URL: lead.url,
      FOLIO_LEAD_CONSOLE_URL: url_for([:console, lead]),
    )
  end
end
