# frozen_string_literal: true

class Folio::DeviseMailer < Devise::Mailer
  include DeviseInvitable::Mailer
  include DeviseInvitable::Controllers::Helpers
  include Folio::MailerBase
  include Folio::MailerEmailTemplates

  layout "folio/mailer"

  around_deliver(if: -> { action_name == "email_login" }) do |_mailer, delivery|
    if logger = ActionMailer::Base.logger
      logger.silence(Logger::INFO, &delivery)
    else
      delivery.call
    end
  end

  default from: ->(*) { site.email },
          bcc: Rails.application.config.folio_mailer_global_bcc

  def devise_mail(record, action, opts = {}, &block)
    full_opts = devise_opts_from_template(opts, action, record)

    return if full_opts.nil?

    # Sign-in proofs must not be copied to the site's system recipients.
    full_opts[:bcc] = nil if action.to_s == "email_login"

    super(record, action, full_opts, &block)
  end

  def reset_password_instructions(record, token, opts = {})
    @site = record.auth_site
    opts = { site: @site }.merge(opts)

    with_user_locale(record, locale: opts[:locale]) do |locale|
      @data ||= {}
      @data[:LOCALE] = locale
      @data[:VALID_UNTIL_TIME] = valid_until_translated(record.class.reset_password_within)
      @data[:USER_CHANGE_PASSWORD_URL] = scoped_url_method(record,
                                                           :edit_password_url,
                                                           reset_password_token: token,
                                                           host: @site.env_aware_domain,
                                                           locale:)

      super(record, token, opts)
    end
  end

  def email_login(challenge, token, locale: nil)
    @site = challenge.site
    @challenge = challenge
    with_user_locale(challenge.user, locale:) do |user_locale|
      @email_login_url = scoped_url_method(challenge.user, :confirm_email_login_url,
                                          anchor: token, host: @site.env_aware_domain, locale: user_locale)
      @data = { LOCALE: user_locale, USER_EMAIL_LOGIN_URL: @email_login_url,
                REQUESTED_AT_TIME: l(challenge.created_at, format: :long),
                VALID_UNTIL_TIME: l(challenge.expires_at, format: :long) }
      devise_mail(challenge.user, :email_login, site: @site)
    end
  end

  def invitation_instructions(record, token, opts = {})
    @site = (record.site_user_links.order(id: :asc).last&.site || record.auth_site)
    opts = { site: @site }.merge(opts)

    with_user_locale(record, locale: opts[:locale]) do |locale|
      @data ||= {}
      @data[:LOCALE] = locale
      @data[:VALID_UNTIL_TIME] = valid_until_translated(record.class.invite_for)
      @data[:USER_ACCEPT_INVITATION_URL] = scoped_url_method(record,
                                                             :accept_invitation_url,
                                                             invitation_token: token,
                                                             host: @site.env_aware_domain,
                                                             locale:)

      super(record, token, opts)
    end
  end

  def confirmation_instructions(record, token, opts = {})
    @token = token
    @site = (record.site_user_links.order(id: :asc).last&.site || record.auth_site)
    opts = { site: @site }.merge(opts)

    with_user_locale(record, locale: opts[:locale]) do |locale|
      @data ||= {}
      @data[:LOCALE] = locale
      @data[:VALID_UNTIL_TIME] = valid_until_translated(record.class.confirm_within)
      @data[:USER_CONFIRMATION_URL] = scoped_url_method(record,
                                                        :confirmation_url,
                                                        confirmation_token: @token,
                                                        host: @site.env_aware_domain,
                                                        locale:)
      super(record, token, opts)
    end
  end

  def omniauth_conflict(authentication, opts = {})
    @authentication = authentication
    @record = Folio::User.find(authentication.conflict_user_id)

    initialize_from_record(@record)

    with_user_locale(@record, locale: opts[:locale]) do |locale|
      template_data = {
        LOCALE: locale,
        USER_CONFLICT_PROVIDER: authentication.human_provider,
        USER_CONFLICT_RESOLVE_URL: main_app.users_auth_resolve_conflict_url(conflict_token: authentication.conflict_token)
      }

      email_template_mail template_data,
                          headers_for(:omniauth_conflict, opts).merge(subject: t("devise.mailer.omniauth_conflict.subject"),
                                                                      mailer: "Devise::Mailer")
    end
  end

  private
    def scoped_url_method(record, method, *args)
      scoped = "user"

      method_name = if method.to_s.include?("confirmation")
        "#{scoped}_#{method}"
      else
        method.to_s.gsub(/\A([a-z]+)_/, "\\1_#{scoped}_")
      end

      extra = {
        only_path: false,
        protocol: (Rails.env.development? && !ENV["FORCE_SSL"]) ? "http" : "https",
      }

      if Folio::Current.enabled_site_for_crossdomain_devise
        extra[:host] = Folio::Current.enabled_site_for_crossdomain_devise.env_aware_domain
      end

      if args.present?
        args[0].merge!(extra)
      else
        args = [extra]
      end

      main_app.send(method_name, *args)
    rescue StandardError
      send(method_name, *args)
    end

    def valid_until_translated(duration)
      if duration.to_i == 0
        t("devise.mailer.valid_until.unlimited")
      else
        l(duration.from_now, format: :long)
      end
    end
end
