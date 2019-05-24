# frozen_string_literal: true

class Folio::LeadMailer < Folio::ApplicationMailer
  def self.email_to(_lead)
    self.system_email
  end

  def self.email_cc(_lead)
    self.system_email_copy
  end

  def self.email_subject(lead)
    "#{Folio::Site.instance.title} #{Folio::Lead.model_name.human} ##{lead.id}"
  end

  def self.email_from(lead)
    lead.email.presence || Folio::Site.instance.email
  end

  def notification_email(lead)
    @lead = lead
    @console_link = true

    mail(to: self.class.email_to(lead),
         cc: self.class.email_cc(lead),
         subject: self.class.email_subject(lead),
         from: self.class.email_from(lead))
  end
end
