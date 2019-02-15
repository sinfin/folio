# frozen_string_literal: true

require 'csv'

class Folio::Console::LeadsController < Folio::Console::BaseController
  load_and_authorize_resource :lead, class: 'Folio::Lead'
  add_breadcrumb Folio::Lead.model_name.human(count: 2), :console_leads_path

  def index
    @leads = @leads.ordered.includes(:visit)

    respond_with(@leads, location: console_leads_path) do |format|
      format.html
      format.csv do
        data = ::CSV.generate(headers: true) do |csv|
          csv << Folio::Lead.csv_attribute_names.map { |a| Folio::Lead.human_attribute_name(a) }
          @leads.each { |lead| csv << lead.csv_attributes }
        end
        filename = "#{Folio::Lead.model_name.human(count: 2)}-#{Date.today}.csv".split('.').map(&:parameterize).join('.')

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
    @leads = Folio::Lead.not_handled.where(id: params.require(:leads))
    @leads.update_all(state: 'handled')
    flash.notice = t('.success')
    respond_with @leads, location: console_leads_path
  end

  private

    def lead_params
      params.require(:lead).permit(:email, :phone, :note)
    end
end
