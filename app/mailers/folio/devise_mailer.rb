# frozen_string_literal: true

class Folio::DeviseMailer < Devise::Mailer
  include DeviseInvitable::Mailer
  include DeviseInvitable::Controllers::Helpers
  include Folio::MailerBase
  include Folio::MailerEmailTemplates

  layout "folio/mailer"

  default from: ->(*) { site.email }

  def devise_mail(record, action, opts = {}, &block)
    full_opts = devise_opts_from_template(opts, action, record)
    super(record, action, full_opts, &block)
  end

  def reset_password_instructions(record, token, opts = {})
    @data ||= {}
    @data[:USER_CHANGE_PASSWORD_URL] = scoped_url_method(record,
                                                         :edit_password_url,
                                                         reset_password_token: token)

    super
  end

  def invitation_instructions(record, token, opts = {})
    @data ||= {}
    @data[:USER_ACCEPT_INVITATION_URL] = scoped_url_method(record,
                                                           :accept_invitation_url,
                                                           invitation_token: token)

    super
  end

  def confirmation_instructions(record, token, opts = {})
    @token = token

    @data ||= {}
    @data[:USER_CONFIRMATION_URL] = scoped_url_method(record,
                                                      :confirmation_url,
                                                      confirmation_token: @token)

    super
  end

  def omniauth_conflict(authentication, opts = {})
    @authentication = authentication
    @record = Folio::User.find(authentication.conflict_user_id)

    initialize_from_record(@record)

    template_data = {
      USER_CONFLICT_PROVIDER: authentication.human_provider,
      USER_CONFLICT_RESOLVE_URL: main_app.users_auth_resolve_conflict_url(conflict_token: authentication.conflict_token)
    }

    email_template_mail template_data,
                        headers_for(:omniauth_conflict, opts).merge(subject: t("devise.mailer.omniauth_conflict.subject"))
  end

  private
    def scoped_url_method(record, method, *args)
      if record.is_a?(Folio::Account)
        scoped = "account"
      else
        scoped = "user"
      end

      method_name = if method.to_s.include?("confirmation")
        "#{scoped}_#{method}"
      else
        method.to_s.gsub(/\A([a-z]+)_/, "\\1_#{scoped}_")
      end

      if Rails.application.config.folio_crossdomain_devise && Folio.site_for_crossdomain_devise
        extra = { only_path: false, host: Folio.site_for_crossdomain_devise.env_aware_domain, protocol: "https" }

        if args.present?
          args[0].merge!(extra)
        else
          args = [extra]
        end
      end

      main_app.send(method_name, *args)
    rescue StandardError
      send(method_name, *args)
    end
end
