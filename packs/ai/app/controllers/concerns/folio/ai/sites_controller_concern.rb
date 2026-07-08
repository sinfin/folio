# frozen_string_literal: true

# Allows the console site form to persist AI settings from the AI tab.
module Folio::Ai::SitesControllerConcern
  private
    def site_params
      permitted = super
      return permitted unless Folio::Ai.config.enabled?

      permitted.merge(params.require(:site).permit(ai_settings: {}))
    end
end
