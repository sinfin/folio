# frozen_string_literal: true

require 'csv'

module Folio
  class Console::LeadsController < Console::BaseController
    load_and_authorize_resource :lead, class: 'Folio::Lead'
    add_breadcrumb Lead.model_name.human(count: 2), :console_leads_path

    def index
      @leads = @leads.ordered.includes(:visit)
      @leads = @leads.filter_by_params(filter_params) if params[:by_query].present?

      respond_with(@leads, location: console_leads_path) do |format|
        format.html
        format.csv do
          data = ::CSV.generate(headers: true) do |csv|
            csv << Lead.csv_attribute_names.map { |a| Lead.human_attribute_name(a) }
            @leads.each { |lead| csv << lead.csv_attributes }
          end
          filename = "#{Lead.model_name.human(count: 2)}-#{Date.today}.csv".split('.').map(&:parameterize).join('.')

          send_data data, filename: filename
        end
      end
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
      respond_with @lead, location: console_leads_path
    end

    def unhandle
      @lead.unhandle!
      respond_with @lead, location: console_leads_path
    end

    def mass_handle
      @leads = Lead.not_handled.where(id: params.require(:leads))
      @leads.update_all(state: 'handled')
      flash.notice = t('.success')
      respond_with @leads, location: console_leads_path
    end

    private

      def lead_params
        params.require(:lead).permit(:email, :phone, :note)
      end
  end
end
