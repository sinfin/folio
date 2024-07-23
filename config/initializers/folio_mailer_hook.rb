# frozen_string_literal: true

load Folio::Engine.root.join("app/lib/folio/mailer_hook.rb")

ActionMailer::Base.register_interceptor(Folio::MailerHook)

if ActionMailer::Base.respond_to?(:register_preview_interceptor)
  ActionMailer::Base.register_preview_interceptor(Folio::MailerHook)
end
