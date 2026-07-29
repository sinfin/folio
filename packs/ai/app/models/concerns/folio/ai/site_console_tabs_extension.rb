# frozen_string_literal: true

# Adds the AI prompts tab to the console site form when records are registered.
module Folio::Ai::SiteConsoleTabsExtension
  def console_form_tabs
    tabs = super
    return tabs unless Folio::Ai.config.enabled?
    return tabs if Folio::Ai.registry.records.blank?
    return tabs if tabs.include?(:ai_prompts)

    tabs + %i[ai_prompts]
  end
end
