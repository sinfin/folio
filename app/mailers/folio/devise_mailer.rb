# frozen_string_literal: true

class Folio::DeviseMailer < Devise::Mailer
  include DeviseInvitable::Mailer
  include DeviseInvitable::Controllers::Helpers
  include Folio::MailerEmailTemplates

  layout "folio/mailer"

  default from: ->(*) { Folio::Site.instance.email }

  def devise_mail(record, action, opts = {}, &block)
    full_opts = devise_opts_from_template(opts, action, record)
    super(record, action, full_opts, &block)
  end

  def reset_password_instructions(record, token, opts = {})
    @data = {
      "USER_CHANGE_PASSWORD_URL" => scoped_url_method(record,
                                                      :edit_password_url,
                                                      record,
                                                      reset_password_token: token)
    }
    super(record, token, opts)
  end

  def invitation_instructions(record, token, opts = {})
    @data = {
      "USER_ACCEPT_INVITATION_URL" => scoped_url_method(record,
                                                        :accept_invitation_url,
                                                        record,
                                                        invitation_token: token)
    }
    super(record, token, opts)
  end

  private
    def scoped_url_method(record, method, *args)
      if record.is_a?(Folio::Account)
        scoped = "account"
      else
        scoped = "user"
      end

      send(method.to_s.gsub(/\A([a-z]+)_/, "\\1_#{scoped}_"), *args)
    end
end
