# frozen_string_literal: true

module Folio
  class LeadMailer < ApplicationMailer
    layout false

    def self.email_to
      Site.last.email
    end

    def self.email_subject
      "#{Site.last.title} lead"
    end

    def notification_email(lead)
      @lead = lead
      mail(to: self.class.email_to,
           subject: self.class.email_subject,
           from: lead.email) do |format|
        format.text
      end
    end
  end
end
