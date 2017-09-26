require_dependency 'folio/application_controller'

module Folio
  class LeadsController < ApplicationController
    def create
      @lead = Lead.new(lead_params)
      success = @lead.save

      LeadMailer.notification_email(@lead).deliver_later if success

      render html: cell('folio/lead_form', @lead)
    end

    private

      def lead_params
        params.require(:lead).permit(:name, :email, :phone, :note)
      end
  end
end
