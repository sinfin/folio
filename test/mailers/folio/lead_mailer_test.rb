# frozen_string_literal: true

require "test_helper"
require "generators/folio/email_templates/email_templates_generator"

class Folio::LeadMailerTest < ActionMailer::TestCase
  setup do
    create_and_host_site
    Folio::EmailTemplatesGenerator.new.seed_records
  end

  test "notification_email" do
    lead = create(:folio_lead, note: "Foo Bar")

    mail = Folio::LeadMailer.notification_email(lead)
    assert_equal [Folio::Site.instance_for_mailers.email], mail.to
    assert_match "Foo Bar", mail.body.encoded
  end
end
