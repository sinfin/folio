# frozen_string_literal: true

class Folio::NewsletterSubscriptionMailer < Folio::ApplicationMailer
  def notification_email(newsletter_subscription)
    @newsletter_subscription = newsletter_subscription
    @console_link = true
    site = Folio::Site.instance
    @subject = "#{site.title} newsletter subscription"

    mail(to: site.email,
         subject: @subject,
         from: newsletter_subscription.email)
  end
end
