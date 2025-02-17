# frozen_string_literal: true

require "test_helper"

class Folio::DeviseMailerTest < ActionMailer::TestCase
  def setup
    super
    create_and_host_site

    @superadmin = create(:folio_user, :superadmin)

    Rails.application.load_tasks
    Rake::Task["folio:email_templates:idp_seed"].reenable
    Rake::Task["folio:email_templates:idp_seed"].invoke
  end

  test "reset_password_instructions" do
    mail = Folio::DeviseMailer.reset_password_instructions(@superadmin, "TOKEN")
    assert_equal [@superadmin.email], mail.to
    assert_match "TOKEN", mail.body.encoded

    mail.deliver

    assert_emails 1
    assert mail.subject.include?("Instrukce k nastavení nového hesla")

    assert mail.text_part.decoded.include?("odkaz pro změnu Vašeho hesla")
    assert mail.html_part.decoded.include?("odkaz pro změnu Vašeho hesla")

    ActionMailer::Base.deliveries.clear

    # ---
    # English locale
    @superadmin.update!(preferred_locale: "en")
    mail = Folio::DeviseMailer.reset_password_instructions(@superadmin, "TOKEN")
    assert_equal [@superadmin.email], mail.to
    assert_match "TOKEN", mail.body.encoded

    mail.deliver

    assert_emails 1
    assert mail.subject.include?("Reset password instructions")

    assert mail.text_part.decoded.include?("a link to change your password")
    assert mail.html_part.decoded.include?("a link to change your password")
  end

  test "invitation_instructions" do
    mail = Folio::DeviseMailer.invitation_instructions(@superadmin, "TOKEN")
    assert_equal [@superadmin.email], mail.to
    assert_match "TOKEN", mail.body.encoded

    mail.deliver

    assert_emails 1
    assert mail.subject.include?("Pozvánka")

    assert mail.text_part.decoded.include?("děkujeme za registraci na webu")
    assert mail.text_part.decoded.include?(@site.title)
    assert mail.text_part.decoded.include?(@site.env_aware_domain)

    assert mail.html_part.decoded.include?("děkujeme za registraci na webu")
    assert mail.html_part.decoded.include?(@site.title)
    assert mail.html_part.decoded.include?(@site.env_aware_domain)

    ActionMailer::Base.deliveries.clear

    # ---
    # English locale
    @superadmin.update!(preferred_locale: "en")
    mail = Folio::DeviseMailer.invitation_instructions(@superadmin, "TOKEN")
    assert_equal [@superadmin.email], mail.to
    assert_match "TOKEN", mail.body.encoded

    mail.deliver

    assert_emails 1
    assert mail.subject.include?("Invitation instructions")

    assert mail.text_part.decoded.include?("thank you for registering at")
    assert mail.text_part.decoded.include?(@site.title)
    assert mail.text_part.decoded.include?(@site.env_aware_domain)

    assert mail.html_part.decoded.include?("thank you for registering at")
    assert mail.html_part.decoded.include?(@site.title)
    assert mail.html_part.decoded.include?(@site.env_aware_domain)
  end

  test "confirmation_instructions" do
    mail = Folio::DeviseMailer.confirmation_instructions(@superadmin, "TOKEN")
    assert_equal [@superadmin.email], mail.to
    assert_match "TOKEN", mail.body.encoded

    mail.deliver

    assert_emails 1
    assert mail.subject.include?("Potvrzení e-mailové adresy")

    assert mail.text_part.decoded.include?("Potvďte prosím vaší e-mailovou adresu")
    assert mail.text_part.decoded.include?(@site.title)

    assert mail.html_part.decoded.include?("Potvďte prosím vaší e-mailovou adresu")
    assert mail.html_part.decoded.include?(@site.title)

    ActionMailer::Base.deliveries.clear

    # ---
    # English locale
    @superadmin.update!(preferred_locale: "en")
    mail = Folio::DeviseMailer.confirmation_instructions(@superadmin, "TOKEN")
    assert_equal [@superadmin.email], mail.to
    assert_match "TOKEN", mail.body.encoded

    mail.deliver

    assert_emails 1
    assert mail.subject.include?("Account e-mail confirmation")

    assert mail.text_part.decoded.include?("kindly confirm your e-mail address")
    assert mail.text_part.decoded.include?(@site.title)

    assert mail.html_part.decoded.include?("kindly confirm your e-mail address")
    assert mail.html_part.decoded.include?(@site.title)
  end

  test "omniauth_conflict" do
    authentication = create(:folio_omniauth_authentication,
                            user: @superadmin, conflict_user_id: @superadmin.id)

    mail = Folio::DeviseMailer.omniauth_conflict(authentication)
    assert_equal [@superadmin.email], mail.to

    mail.deliver

    assert_emails 1
    assert mail.subject.include?("Dokončení přihlášení")

    assert mail.text_part.decoded.include?("pro dokončení")
    assert mail.html_part.decoded.include?("pro dokončení")

    ActionMailer::Base.deliveries.clear

    # ---
    # English locale
    @superadmin.update!(preferred_locale: "en")
    mail = Folio::DeviseMailer.omniauth_conflict(authentication)
    assert_equal [@superadmin.email], mail.to

    mail.deliver

    assert_emails 1
    assert mail.subject.include?("Complete the login verification")

    assert mail.text_part.decoded.include?("to finish signing in via")
    assert mail.html_part.decoded.include?("to finish signing in via")
  end

  test "inactive email template does not send email" do
    Folio::EmailTemplate.where(mailer: "Devise::Mailer", site: @site).update_all(active: false)

    mail = Folio::DeviseMailer.reset_password_instructions(@superadmin, "TOKEN")
    mail.deliver

    assert_emails 0

    mail = Folio::DeviseMailer.invitation_instructions(@superadmin, "TOKEN")
    mail.deliver

    assert_emails 0

    mail = Folio::DeviseMailer.confirmation_instructions(@superadmin, "TOKEN")
    mail.deliver

    assert_emails 0

    authentication = create(:folio_omniauth_authentication,
                            user: @superadmin, conflict_user_id: @superadmin.id)
    mail = Folio::DeviseMailer.omniauth_conflict(authentication)
    mail.deliver

    assert_emails 0
  end
end
