# frozen_string_literal: true

require "test_helper"

class Folio::LeadMailerTest < ActionMailer::TestCase
  def setup
    super
    create_and_host_site
    Rails.application.load_tasks
    Rake::Task["folio:email_templates:idp_seed"].reenable
    Rake::Task["folio:email_templates:idp_seed"].invoke
  end

  test "notification_email" do
    lead = create(:folio_lead, note: "Foo Bar")

    mail = Folio::LeadMailer.notification_email(lead)
    assert_equal [Folio.site_instance_for_mailers.email], mail.to
    assert_match "Foo Bar", mail.body.encoded

    mail.deliver

    assert_emails 1
    assert mail.subject.include?("nový formulář")

    assert mail.text_part.decoded.include?("Telefon")
    assert mail.html_part.decoded.include?("Telefon")

    ActionMailer::Base.deliveries.clear

    # ---
    # English locale
    @site.update!(locale: :en)
    mail = Folio::LeadMailer.notification_email(lead)
    assert_equal [Folio.site_instance_for_mailers.email], mail.to
    assert_match "Foo Bar", mail.body.encoded

    mail.deliver

    assert_emails 1
    assert mail.subject.include?("new lead")

    assert mail.text_part.decoded.include?("Phone")
    assert mail.html_part.decoded.include?("Phone")
  end

  test "inactive email template does not send email" do
    Folio::EmailTemplate.where(mailer: "Folio::LeadMailer", site: @site).update_all(active: false)

    lead = create(:folio_lead, note: "Foo Bar")

    mail = Folio::LeadMailer.notification_email(lead)
    mail.deliver

    assert_emails 0
  end
end
