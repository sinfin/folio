# frozen_string_literal: true

module Folio
  # Concern for controllers that need to respect session requirements from rendered components.
  #
  # Components can indicate they need session state by calling `require_session_for_component!`
  # during rendering. This allows form atoms and other interactive components to work correctly
  # on cached pages by disabling session optimization when needed.
  #
  # Usage in component:
  #   class MyFormComponent < ApplicationComponent
  #     def initialize(...)
  #       super
  #       require_session_for_component!("form_with_csrf")
  #     end
  #   end
  #
  module ComponentSessionRequirements
    extend ActiveSupport::Concern

    included do
      # Track session requirements from rendered components
      attr_accessor :component_session_requirements

      # Initialize session requirements tracking
      before_action :initialize_component_session_requirements
    end

    # Check if any rendered components require session state
    def component_requires_session?
      component_session_requirements.present?
    end

    private
      def initialize_component_session_requirements
        @component_session_requirements = []
      end

      # Override from cache optimization concern
      def should_skip_cookies_for_cache?
        # If any component requires session, don't skip cookies
        return false if component_requires_session?

        # Delegate to parent implementation
        super if defined?(super)
      end

      # Override from cache headers concern
      def should_skip_session_for_cache?
        # Auto-analyze @page if it exists and has atoms
        if defined?(@page) && @page&.respond_to?(:atoms)
          analyze_page_session_requirements(@page)
        end

        # If any component requires session, don't skip session
        return false if component_requires_session?

        # Delegate to parent implementation
        super if defined?(super)
      end

      # Override from cache headers concern
      def should_use_private_cache?
        # Auto-analyze @page if it exists and has atoms
        if defined?(@page) && @page&.respond_to?(:atoms)
          analyze_page_session_requirements(@page)
        end

        # If any component requires session, use private cache
        return true if component_requires_session?

        # Delegate to parent implementation (signed-in users)
        super if defined?(super)
      end

      # Helper method components can call to indicate session requirement
      def require_session_for_component!(reason)
        @component_session_requirements ||= []
        @component_session_requirements << {
          reason: reason,
          component: caller_locations(1, 1).first&.label || "unknown",
          timestamp: Time.current
        }
      end

      # Analyze page atoms to determine session requirements before cache headers are set
      # This is necessary because components render AFTER cache headers, creating a timing issue
      def analyze_page_session_requirements(page)
        return unless page.respond_to?(:atoms)

        page.atoms.each do |atom|
          # Check if atom declares session requirements via ComponentSessionHelper concern
          if atom.respond_to?(:requires_session?) && atom.requires_session?
            @component_session_requirements ||= []
            @component_session_requirements << atom.session_requirement
          end
        end
      end
  end
end
