# frozen_string_literal: true

require "test_helper"

class Folio::Users::EmailLoginDeliveryJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  def setup
    super
    travel_to Time.current
    @site = create_and_host_site
    @user = create(:folio_user, auth_site: @site)
    @nonce = SecureRandom.hex(32)
    @challenge, @token = Folio::Devise::EmailLogin::IssueChallenge.call(user: @user, site: @site,
                                                                     nonce: @nonce, purpose: "magic_link")
    ActionMailer::Base.deliveries.clear
  end

  test "delivery uses the challenge site and original expiration even after queue delay" do
    job = delivery_job(locale: "en")
    travel 2.minutes
    events = []
    ActiveSupport::Notifications.subscribed(->(*args) { events << args.last }, "email_login.folio") do
      assert_emails 1 do
        job.perform_now
      end
    end
    assert_equal [{ event: "delivered", site_id: @site.id, purpose: "magic_link", count: 1, kind: "counter" }], events
    mail = ActionMailer::Base.deliveries.last
    assert_equal [@user.email], mail.to
    assert_equal I18n.t("devise.mailer.email_login.subject", locale: :en), mail.subject
    body = mail.html_part&.decoded || mail.body.decoded
    assert_includes body, @site.env_aware_domain
    assert_includes body, @token
    link = Nokogiri::HTML(body).css("a[href]").map { |anchor| URI.parse(anchor["href"]) }.find { |uri| uri.fragment == @token }
    assert_not_nil link
    assert_not_includes link.query.to_s, @token
    assert_not_includes link.query.to_s, "email_login_token"
    assert_not_includes body, @nonce
    assert_includes body,
                    "Confirm the login to #{@site.title} — you'll be signed in on the browser where you started logging in."
    assert_includes body, "If you did not request this, please ignore this email."
    assert_includes body, "With kind regards,"
    assert_equal 2, Nokogiri::HTML(body).css("a[href]").count { |anchor| URI.parse(anchor["href"]).fragment == @token }
    assert_equal 0, @user.reload.sign_in_count
  end

  test "debug mail logging cannot expose the sign-in proof" do
    output = StringIO.new
    logger = ActiveSupport::Logger.new(output)
    logger.level = Logger::DEBUG
    ActionMailer::Base.stub(:logger, logger) do
      assert_emails(1) { delivery_job.perform_now }
      logger.debug("Logging remains enabled")
    end
    assert_includes output.string, "Logging remains enabled"
    assert_not_includes output.string, @token
    assert_equal Logger::DEBUG, logger.level
    mail = ActionMailer::Base.deliveries.last
    assert_includes mail.html_part&.decoded || mail.body.decoded, @token
  end

  test "expired or replaced links are not delivered by a delayed job" do
    job = delivery_job
    travel_to @challenge.expires_at
    assert_emails 0 do
      job.perform_now
    end
  end

  test "revoked and mismatched tokens are not delivered" do
    assert_emails 0 do
      delivery_job(token: @nonce).perform_now
      job = delivery_job
      @challenge.update!(revoked_at: Time.current)
      job.perform_now
    end
  end

  test "changed credentials prevent queued delivery" do
    job = delivery_job
    @user.update!(password: "Changed@Password123")
    assert_emails 0 do
      job.perform_now
    end
  end

  test "editable email templates retain site locale and never copy sign-in proofs" do
    Folio::EmailTemplate.load_templates_from_yaml(Folio::Engine.root.join("data/email_templates_data.yml"))
    @site.update!(system_email_copy: "copy@example.test")
    assert_emails 1 do
      delivery_job.perform_now
    end
    mail = ActionMailer::Base.deliveries.last
    assert_nil mail.bcc
    assert_equal [@user.email], mail.to
    assert_equal "Potvrzení přihlášení", mail.subject
    assert_includes mail.html_part.decoded, @token
    assert_includes mail.text_part.decoded, @token
    assert_includes mail.text_part.decoded, @site.title
    assert_includes mail.text_part.decoded,
                    "Potvrďte přihlášení na #{@site.title} — přihlásíte se tím v prohlížeči, ve kterém jste přihlášení zahájili."
    assert_includes mail.text_part.decoded, "Pokud jste si toto nevyžádali, ignorujte tento e-mail."
    assert_includes mail.text_part.decoded, "S přátelským pozdravem"

    links = Nokogiri::HTML(mail.html_part.decoded).css("a[href]").select do |anchor|
      URI.parse(anchor["href"]).fragment == @token
    end
    assert_equal 2, links.size
  end

  test "queue arguments contain neither the email proof nor the browser secret" do
    job = delivery_job
    serialized = job.serialize.to_json
    assert_not_includes serialized, @token
    assert_not_includes serialized, @nonce
    assert_equal false, Folio::Users::EmailLoginDeliveryJob.log_arguments
    assert_emails 0 do
      Folio::Users::EmailLoginDeliveryJob.perform_now(@challenge.id + 1, job.arguments[1], "cs")
      Folio::Users::EmailLoginDeliveryJob.perform_now(@challenge.id, "invalid payload", "cs")
    end
  end

  private
    def delivery_job(token: @token, locale: "cs")
      Folio::Users::EmailLoginDeliveryJob.deliver_later(@challenge, token, locale:)
    end
end
