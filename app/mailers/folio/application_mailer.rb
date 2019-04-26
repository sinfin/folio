# frozen_string_literal: true

class Folio::ApplicationMailer < ActionMailer::Base
  include Folio::Engine.routes.url_helpers

  default from: 'from@example.com'
  layout 'folio/mailer'
end
