# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/folio/newsletter_subscription_mailer
class Folio::NewsletterSubscriptionMailerPreview < ActionMailer::Preview
  def notification_email
    unless Folio::NewsletterSubscription.exists?
      Folio::NewsletterSubscription.create!(email: 'foo@bar.baz')
    end

    Folio::NewsletterSubscriptionMailer.notification_email(Folio::NewsletterSubscription.first).tap do |email|
      Premailer::Rails::Hook.perform(email)
    end
  end
end
