# frozen_string_literal: true

require "folio/mailer_hook"

ActionMailer::Base.register_interceptor(Folio::MailerHook)

if ActionMailer::Base.respond_to?(:register_preview_interceptor)
  ActionMailer::Base.register_preview_interceptor(Folio::MailerHook)
end
