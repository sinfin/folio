# frozen_string_literal: true

module Folio
  class Console::LeadsController < Console::BaseController
    load_and_authorize_resource :lead, class: 'Folio::Lead'

    add_breadcrumb(I18n.t('folio.console.leads.index.title'),
                   :console_leads_path)

    def index
      @leads = @leads.filter(filter_params) if params[:by_query].present?
      @leads = @leads.page(current_page)
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

    private

      def lead_params
        params.require(:lead).permit(:email, :phone, :note)
      end
  end
end
