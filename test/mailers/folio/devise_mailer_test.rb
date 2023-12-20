# frozen_string_literal: true

require "test_helper"

class Folio::DeviseMailerTest < ActionMailer::TestCase
  setup do
    create_and_host_site
    Rails.application.load_tasks
    Rake::Task["folio:email_templates:idp_seed"].reenable
    Rake::Task["folio:email_templates:idp_seed"].invoke
  end

  test "reset_password_instructions" do
    superadmin = create(:folio_user, :superadmin)

    mail = Folio::DeviseMailer.reset_password_instructions(superadmin, "TOKEN")
    assert_equal [superadmin.email], mail.to
    assert_match "TOKEN", mail.body.encoded
  end

  test "invitation_instructions" do
    superadmin = create(:folio_user, :superadmin)

    mail = Folio::DeviseMailer.invitation_instructions(superadmin, "TOKEN")
    assert_equal [superadmin.email], mail.to
    assert_match "TOKEN", mail.body.encoded
  end
end
