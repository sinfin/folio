# frozen_string_literal: true

class Folio::DeviseMailer < Devise::Mailer
  include DeviseInvitable::Mailer
  include DeviseInvitable::Controllers::Helpers
  include Folio::MailerEmailTemplates

  layout "folio/mailer"

  default from: ->(*) { Folio.site_instance_for_mailers.email }

  def devise_mail(record, action, opts = {}, &block)
    full_opts = devise_opts_from_template(opts, action, record)
    super(record, action, full_opts, &block)
  end

  def reset_password_instructions(record, token, opts = {})
    @data = {
      USER_CHANGE_PASSWORD_URL: scoped_url_method(record,
                                                  :edit_password_url,
                                                  reset_password_token: token)
    }
    super(record, token, opts)
  end

  def invitation_instructions(record, token, opts = {})
    @data ||= {}
    @data[:USER_ACCEPT_INVITATION_URL] = scoped_url_method(record,
                                                           :accept_invitation_url,
                                                           invitation_token: token)

    super(record, token, opts)
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

  def self.system_email
    if Folio.site_instance_for_mailers.system_email.present?
      Folio.site_instance_for_mailers.system_email_array
    else
      Folio.site_instance_for_mailers.email
    end
  end

  def self.system_email_copy
    Folio.site_instance_for_mailers.system_email_copy_array if Folio.site_instance_for_mailers.system_email_copy.present?
  end

  private
    def scoped_url_method(record, method, *args)
      if record.is_a?(Folio::Account)
        scoped = "account"
      else
        scoped = "user"
      end

      method_name = method.to_s.gsub(/\A([a-z]+)_/, "\\1_#{scoped}_")

      if Rails.application.config.folio_crossdomain_devise && Folio.site_for_crossdomain_devise
        extra = { only_path: false, host: Folio.site_for_crossdomain_devise.env_aware_domain }

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
