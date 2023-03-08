# frozen_string_literal: true

class Folio::ApplicationMailer < ActionMailer::Base
  include Folio::Engine.routes.url_helpers
  include Folio::MailerBase
  include Folio::MailerEmailTemplates

  default from: -> { site.email_from.presence || site.email }
  layout "folio/mailer"

  def cell(name, model = nil, options = {}, constant = ::Cell::ViewModel, &block)
    options[:context] ||= {}
    options[:context][:controller] = self
    options[:context][:mailer] = self

    constant.cell(name, model, options, &block)
  end
end
