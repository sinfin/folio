# frozen_string_literal: true

class Folio::LeadMailer < Folio::ApplicationMailer
  def self.email_to(_lead)
    Folio::Site.instance.email
  end

  def self.email_subject(_lead)
    "#{Folio::Site.instance.title} lead"
  end

  def self.email_from(lead)
    lead.email.presence || Folio::Site.instance.email
  end

  def notification_email(lead)
    @lead = lead
    @console_link = true
    @subject = self.class.email_subject(lead)

    mail(to: self.class.email_to(lead),
         subject: @subject,
         from: self.class.email_from(lead))
  end
end
