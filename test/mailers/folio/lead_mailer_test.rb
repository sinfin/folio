# frozen_string_literal: true

require "test_helper"

class Folio::LeadMailerTest < ActionMailer::TestCase
  setup do
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
  end
end
