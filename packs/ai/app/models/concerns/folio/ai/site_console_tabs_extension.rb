# frozen_string_literal: true

module Folio::Ai::SiteConsoleTabsExtension
  def console_form_tabs
    tabs = super

    if Folio::Ai.config.enabled? && Folio::Ai.registry.integrations_for_select.present?
      tabs + %i[ai_prompts]
    else
      tabs
    end
  end
end
