# frozen_string_literal: true

require "test_helper"
require "generators/folio/email_templates/email_templates_generator"

class Folio::DeviseMailerTest < ActionMailer::TestCase
  setup do
    create_and_host_site
    Folio::EmailTemplatesGenerator.new.seed_records
  end

  test "reset_password_instructions" do
    account = create(:folio_admin_account)

    mail = Folio::DeviseMailer.reset_password_instructions(account, "TOKEN")
    assert_equal [account.email], mail.to
    assert_match "TOKEN", mail.body.encoded
  end

  test "invitation_instructions" do
    account = create(:folio_admin_account)

    mail = Folio::DeviseMailer.invitation_instructions(account, "TOKEN")
    assert_equal [account.email], mail.to
    assert_match "TOKEN", mail.body.encoded
  end
end
