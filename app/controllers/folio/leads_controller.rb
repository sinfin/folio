# frozen_string_literal: true

module Folio
  class LeadsController < ApplicationController
    invisible_captcha only: :create

    REMEMBER_OPTION_KEYS = [
      :note,
      :message,
      :name,
      :note_label,
      :above_submit_content,
    ]

    def create
      @lead = Lead.new(lead_params.merge(url: request.referrer,
                                         visit: current_visit))
      success = @lead.save

      LeadMailer.notification_email(@lead).deliver_later if success

      render html: cell('folio/lead_form', @lead, cell_options_params)
    end

    private

      def lead_params
        params.require(:lead).permit(:name,
                                     :email,
                                     :phone,
                                     :note,
                                     :additional_data).tap do |obj|
          if obj[:additional_data].present?
            obj[:additional_data] = JSON.parse(obj[:additional_data])
          else
            obj[:additional_data] = nil
          end
        end
      end

      def cell_options_params
        cell_options = params[:cell_options]
        if cell_options
          cell_options.permit(*REMEMBER_OPTION_KEYS)
        else
          {}
        end
      end
  end
end
