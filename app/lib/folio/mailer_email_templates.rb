# frozen_string_literal: true

module Folio::MailerEmailTemplates
  def email_template_for(action = nil, mailer: nil, bang: false)
    action ||= action_name
    mailer ||= self.class.to_s

    find_by = { mailer:, action:, site: }

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
    @data = sym_data
    @site = opts.delete(:site)
    @email_template = email_template_for!(mailer: opts.delete(:mailer))

    @data[:ROOT_URL] = site.env_aware_root_url
    @data[:SITE_TITLE] = site.title
    @data[:DOMAIN] = site.env_aware_domain

    @data = @data.stringify_keys

    opts[:subject] = @email_template.render_subject(@data, locale: @data["LOCALE"])
    opts[:to] ||= system_email
    opts[:bcc] = email_template_bcc_string(opts[:bcc])
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
      @data[:DOMAIN] = site.env_aware_domain
      @data[:USER_EMAIL] = record.email
      @data[:LOCALE] = record.preferred_locale

      @data = @data.stringify_keys

      opts[:subject] = @email_template.render_subject(@data, locale: @data["LOCALE"])
      opts[:bcc] = email_template_bcc_string(opts[:bcc])
      opts[:from] ||= site.email_from.presence || site.email
      opts[:template_path] = "folio/email_templates"
      opts[:template_name] = "mail"
    end

    opts
  end

  def email_template_bcc_string(bcc)
    ary = if bcc.present?
      if bcc.is_a?(String)
        bcc.split(/,\s+/)
      elsif bcc.is_a?(Array)
        bcc
      else
        []
      end
    else
      []
    end

    if system_email_copy.present?
      if system_email_copy.is_a?(String)
        ary << system_email_copy
      elsif system_email_copy.is_a?(Array)
        ary += system_email_copy
      end
    end

    if Rails.application.config.folio_mailer_global_bcc.present?
      ary << Rails.application.config.folio_mailer_global_bcc
    end

    ary.uniq.join(", ")
  end
end
