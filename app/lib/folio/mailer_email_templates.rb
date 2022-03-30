# frozen_string_literal: true

module Folio::MailerEmailTemplates
  def email_template_for(action = nil, mailer: nil)
    action ||= action_name
    mailer ||= self.class.to_s
    Folio::EmailTemplate.find_by(mailer:, action:)
  end

  def email_template_for!(action = nil, mailer: nil)
    action ||= action_name
    mailer ||= self.class.to_s
    Folio::EmailTemplate.find_by!(mailer:, action:)
  end

  def email_template_mail(sym_data = {}, opts = {})
    @data = sym_data.stringify_keys
    @email_template = email_template_for!

    @data[:ROOT_URL] = root_url(only_path: false)
    @data[:DOMAIN] = Folio::Site.instance_for_mailers.domain

    opts[:subject] = @email_template.render_subject(@data)
    opts[:to] ||= self.class.system_email
    opts[:cc] ||= self.class.system_email_copy
    opts[:from] ||= Folio::Site.instance_for_mailers.email
    opts[:template_path] = "folio/email_templates"
    opts[:template_name] = "mail"

    mail(opts)
  end

  def devise_opts_from_template(source_opts, action, record)
    opts = source_opts.dup
    @email_template = email_template_for(action, mailer: "Devise::Mailer")

    if @email_template.present?
      @data ||= {}
      @data[:ROOT_URL] = root_url(only_path: false)
      @data[:DOMAIN] = Folio::Site.instance_for_mailers.domain
      @data[:USER_EMAIL] = record.email

      opts[:subject] = @email_template.render_subject(@data)
      opts[:template_path] = "folio/email_templates"
      opts[:template_name] = "mail"
    end

    opts
  end
end
