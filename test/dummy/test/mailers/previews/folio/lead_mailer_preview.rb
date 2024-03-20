# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/folio/lead_mailer
class Folio::LeadMailerPreview < ActionMailer::Preview
  def notification_email
    unless Folio::Lead.exists?
      Folio::Lead.create!(email: "foo@bar.baz",
                          phone: "+420 123456789",
                          note: "Hello",
                          site: Folio::Site.first)
    end

    Folio::LeadMailer.notification_email(Folio::Lead.first).tap do |email|
      Premailer::Rails::Hook.perform(email)
    end
  end
end
