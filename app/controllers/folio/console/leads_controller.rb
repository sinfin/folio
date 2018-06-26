# frozen_string_literal: true

module Folio
  class Console::LeadsController < Console::BaseController
    load_and_authorize_resource :lead, class: 'Folio::Lead'
    add_breadcrumb Lead.model_name.human(count: 2), :console_leads_path

    def index
      @leads = @leads.filter(filter_params) if params[:by_query].present?
      respond_with @leads, location: console_leads_path
    end

    def update
      @lead.update(lead_params)
      respond_with @lead, location: console_leads_path
    end


    def destroy
      @lead.destroy
      respond_with @lead, location: console_leads_path
    end

    def show
      respond_with @lead, location: console_leads_path
    end

    def handle
      @lead.handle!
      redirect_back fallback_location: console_leads_path
    end

    def unhandle
      @lead.unhandle!
      redirect_back fallback_location: console_leads_path
    end

    private

      def lead_params
        params.require(:lead).permit(:email, :phone, :note)
      end
  end
end
