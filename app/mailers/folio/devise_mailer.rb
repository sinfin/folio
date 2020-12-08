# frozen_string_literal: true

class Folio::DeviseMailer < Devise::Mailer
  include DeviseInvitable::Mailer
  include DeviseInvitable::Controllers::Helpers
  include Folio::MailerEmailTemplates

  layout "folio/mailer"

  default from: ->(*) { Folio::Site.instance.email }

  def devise_mail(record, action, opts = {}, &block)
    @email_template = email_template_for(action, mailer: "Devise::Mailer")

    if @email_template.present?
      @data ||= {}
      @data["USER_EMAIL"] = record.email

      opts[:template_path] = "folio/email_templates"
      opts[:template_name] = "mail"
      opts[:subject] = @email_template.render_subject(@data)
    end

    super(record, action, opts, &block)
  end

  def confirmation_instructions(record, token, opts = {})
    super(record, token, opts)
  end

  def reset_password_instructions(record, token, opts = {})
    @data = {
      "CHANGE_PASSWORD_URL" => scoped_url_method(record,
                                                 :edit_password_url,
                                                 record,
                                                 reset_password_token: token)
    }
    super(record, token, opts)
  end

  def unlock_instructions(record, token, opts = {})
    super(record, token, opts)
  end

  def email_changed(record, opts = {})
    super(record, opts)
  end

  def password_change(record, opts = {})
    super(record, opts)
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
