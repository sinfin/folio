# frozen_string_literal: true

module Folio
  class LeadMailer < ApplicationMailer
    layout false

    def self.email_to(_lead)
      Site.last.email
    end

    def self.email_subject(_lead)
      "#{Site.last.title} lead"
    end

    def notification_email(lead)
      @lead = lead
      mail(to: self.class.email_to(lead),
           subject: self.class.email_subject(lead),
           from: lead.email) do |format|
        format.text
      end
    end
  end
end
