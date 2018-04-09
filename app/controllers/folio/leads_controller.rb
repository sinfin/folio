# frozen_string_literal: true

module Folio
  class LeadsController < ApplicationController
    invisible_captcha only: :create, on_timestamp_spam: :on_timestamp_spam

    def create
      on_timestamp_spam
      @lead = Lead.new(lead_params.merge(url: request.referrer))
      success = @lead.save

      LeadMailer.notification_email(@lead).deliver_later if success

      render html: cell('folio/lead_form', @lead, cell_options_params)
    end

    private

      def lead_params
        params.require(:lead).permit(:name, :email, :phone, :note)
      end

      def cell_options_params
        cell_options = params[:cell_options]
        if cell_options
          cell_options.permit(:note, :message, :name, :note_label)
        else
          {}
        end
      end

      def on_timestamp_spam
        send(200)
      end
  end
end
