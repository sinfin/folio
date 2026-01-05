# frozen_string_literal: true

module Folio
  # Helper concern for atoms/components that need session state.
  #
  # Components that require session (e.g., forms with CSRF) should include this concern
  # and define their session requirements.
  #
  # Usage in atom:
  #   class MyFormAtom < Folio::Atom::Base
  #     include Folio::ComponentSessionHelper
  #
  #     def session_requirement_reason
  #       "form_with_csrf"
  #     end
  #   end
  #
  module ComponentSessionHelper
    extend ActiveSupport::Concern

    # Default implementation - components can override
    def requires_session?
      true
    end

    # Default session requirement details - components should override
    def session_requirement
      {
        reason: session_requirement_reason,
        component: "#{self.class.name}_atom",
        timestamp: Time.current
      }
    end

    # Override this in your component to specify the reason
    def session_requirement_reason
      "unknown_session_requirement"
    end
  end
end
