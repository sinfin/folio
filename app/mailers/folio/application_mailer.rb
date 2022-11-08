# frozen_string_literal: true

class Folio::ApplicationMailer < ActionMailer::Base
  include Folio::Engine.routes.url_helpers
  include Folio::MailerBase
  include Folio::MailerEmailTemplates

  default from: -> { site.email_from.presence || site.email }
  layout "folio/mailer"
end
