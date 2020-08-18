# frozen_string_literal: true

class Folio::Console::LeadsController < Folio::Console::BaseController
  folio_console_controller_for "Folio::Lead"

  def index
    @leads = @leads.ordered.includes(:visit)

    respond_with(@leads) do |format|
      format.html { @pagy, @leads = pagy(@leads) }
      format.csv { render_csv(@leads) }
    end
  end

  def mass_handle
    @leads = Folio::Lead.not_handled.where(id: params.require(:leads))
    @leads.update_all(aasm_state: "handled")
    flash.notice = t(".success")
    respond_with @leads
  end

  private
    def index_filters
      {
        by_state: Folio::Lead.aasm.states_for_select,
      }
    end

    def lead_params
      params.require(:lead)
            .permit(:aasm_state,
                    :name,
                    :email,
                    :phone,
                    :note,
                    :url,
                    :additional_data)
    end
end
