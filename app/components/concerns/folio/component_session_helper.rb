# frozen_string_literal: true

module Folio
  # Helper module for components that need to indicate session requirements.
  #
  # When a component requires session state (e.g., for CSRF tokens, form submissions),
  # it can use this helper to communicate that requirement to the parent controller.
  #
  # Usage:
  #   class MyFormComponent < ApplicationComponent
  #     include Folio::ComponentSessionHelper
  #
  #     def initialize(...)
  #       super
  #       require_session_for_component!("contact_form_csrf")
  #     end
  #   end
  #
  module ComponentSessionHelper
    extend ActiveSupport::Concern

    # Indicate that this component requires session state
    #
    # @param reason [String] descriptive reason for debugging
    #
    def require_session_for_component!(reason)
      # Find the current controller through the view context
      if respond_to?(:helpers) && helpers.present? &&
         helpers.respond_to?(:controller) &&
         helpers.controller.respond_to?(:require_session_for_component!)
        helpers.controller.require_session_for_component!(reason)
      else
        # Fallback for debugging - log the requirement
        unless Rails.env.production?
          Rails.logger.warn "[ComponentSession] Component #{self.class.name} requires session (#{reason}) but controller doesn't support ComponentSessionRequirements"
        end
      end
    rescue ViewComponent::HelpersCalledBeforeRenderError
      # Gracefully handle when called before rendering context is available
      unless Rails.env.production?
        Rails.logger.warn "[ComponentSession] Component #{self.class.name} requires session (#{reason}) but called before rendering context available"
      end
    end

    # Check if current request has session support
    def session_available?
      helpers.respond_to?(:session) && helpers.session.respond_to?(:id)
    end

    # Get CSRF token if available
    def csrf_token
      if helpers.respond_to?(:form_authenticity_token)
        helpers.form_authenticity_token
      end
    end
  end
end
