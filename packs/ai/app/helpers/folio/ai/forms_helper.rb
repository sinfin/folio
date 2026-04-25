# frozen_string_literal: true

module Folio::Ai::FormsHelper
  def folio_ai_form_context(integration_key:,
                            endpoint:,
                            record: nil,
                            site: Folio::Current.site,
                            user: Folio::Current.user,
                            current_state_policy: :persisted_record,
                            host_eligible: true,
                            disabled: false,
                            &block)
    context = Folio::Ai::FormContext.new(integration_key:,
                                         endpoint:,
                                         record:,
                                         site:,
                                         user:,
                                         current_state_policy:,
                                         host_eligible:,
                                         disabled:)

    return context unless block

    previous_context = @folio_ai_form_context
    @folio_ai_form_context = context

    capture(&block)
  ensure
    @folio_ai_form_context = previous_context if block
  end

  def current_folio_ai_form_context
    @folio_ai_form_context
  end
end
