# frozen_string_literal: true

module Folio::MailerEmailTemplates
  def email_template_for(action, mailer: nil)
    mailer ||= self.class.to_s
    Folio::EmailTemplate.find_by(mailer: mailer, action: action)
  end
end
