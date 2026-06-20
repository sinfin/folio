# frozen_string_literal: true

module Folio::Ai::SitesControllerConcern
  private
    def site_params
      permitted = super
      return permitted unless Folio::Ai.enabled?

      permitted.merge(params.require(:site).permit(ai_settings: {}))
    end
end
