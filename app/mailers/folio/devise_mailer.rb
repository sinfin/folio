# frozen_string_literal: true

class Folio::DeviseMailer < Devise::Mailer
  include DeviseInvitable::Mailer
  include DeviseInvitable::Controllers::Helpers
  include Folio::MailerBase
  include Folio::MailerEmailTemplates

  layout "folio/mailer"

  default from: ->(*) { site.email },
          bcc: Rails.application.config.folio_mailer_global_bcc

  def devise_mail(record, action, opts = {}, &block)
    full_opts = devise_opts_from_template(opts, action, record)
    super(record, action, full_opts, &block)
  end

  def reset_password_instructions(record, token, opts = {})
    @site = record.auth_site
    opts = { site: @site }.merge(opts)

    with_locale(record, opts) do |locale|
      @data ||= {}
      @data[:LOCALE] = locale
      @data[:USER_CHANGE_PASSWORD_URL] = scoped_url_method(record,
                                                           :edit_password_url,
                                                           reset_password_token: token,
                                                           host: @site.env_aware_domain,
                                                           locale:)

      super(record, token, opts)
    end
  end

  def invitation_instructions(record, token, opts = {})
    @site = (record.site_user_links.order(id: :asc).last&.site || record.auth_site)
    opts = { site: @site }.merge(opts)

    with_locale(record, opts) do |locale|
      @data ||= {}
      @data[:LOCALE] = locale
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

    with_locale(record, opts) do |locale|
      @data ||= {}
      @data[:LOCALE] = locale
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

    with_locale(@record, opts) do |locale|
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
    def with_locale(record, opts)
      locale = opts[:locale] || record.preferred_locale || record.auth_site.locale
      I18n.with_locale(locale) do
        yield locale
      end
    end

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

      if Folio.enabled_site_for_crossdomain_devise
        extra[:host] = Folio.enabled_site_for_crossdomain_devise.env_aware_domain
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
end
