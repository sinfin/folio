# frozen_string_literal: true

module Folio
  class LeadMailer < ApplicationMailer
    layout false

    def notification_email(lead)
      @lead = lead
      site = Folio::Site.last
      mail(to: site.email,
           subject: "#{site.title} lead",
           from: lead.email) do |format|
        format.text
      end
    end
  end
end
