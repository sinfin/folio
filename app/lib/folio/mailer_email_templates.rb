# frozen_string_literal: true

module Folio::MailerEmailTemplates
  def email_template_for(action = nil, mailer: nil, bang: false)
    action ||= action_name
    mailer ||= self.class.to_s

    find_by = { mailer:, action: }

    unless Rails.application.config.folio_site_is_a_singleton
      find_by[:site] = site
    end

    if bang
      Folio::EmailTemplate.find_by!(find_by)
    else
      Folio::EmailTemplate.find_by(find_by)
    end
  end

  def email_template_for!(action = nil, mailer: nil)
    email_template_for(action, mailer:, bang: true)
  end

  def email_template_mail(sym_data = {}, opts = {})
    @data = sym_data.stringify_keys
    @site = opts.delete(:site)
    @email_template = email_template_for!(mailer: opts.delete(:mailer))

    @data[:ROOT_URL] = site.env_aware_root_url
    @data[:SITE_TITLE] = site.title
    @data[:DOMAIN] = site.domain

    opts[:subject] = @email_template.render_subject(@data)
    opts[:to] ||= system_email
    opts[:bcc] ||= system_email_copy
    opts[:from] ||= site.email_from.presence || site.email
    opts[:template_path] = "folio/email_templates"
    opts[:template_name] = "mail"

    mail(opts)
  end

  def devise_opts_from_template(source_opts, action, record)
    opts = source_opts.dup
    @email_template = email_template_for(action, mailer: "Devise::Mailer")

    if @email_template.present?
      @data ||= {}
      @data[:ROOT_URL] = site.env_aware_root_url
      @data[:SITE_TITLE] = site.title
      @data[:DOMAIN] = site.domain
      @data[:USER_EMAIL] = record.email

      opts[:subject] = @email_template.render_subject(@data)
      opts[:bcc] ||= system_email_copy
      opts[:from] ||= site.email_from.presence || site.email
      opts[:template_path] = "folio/email_templates"
      opts[:template_name] = "mail"
    end

    opts
  end
end
