# frozen_string_literal: true

class Folio::DeviseMailer < Devise::Mailer
  include DeviseInvitable::Mailer
  include DeviseInvitable::Controllers::Helpers

  layout "folio/mailer"

  default from: ->(*) { Folio::Site.instance.email }
end
