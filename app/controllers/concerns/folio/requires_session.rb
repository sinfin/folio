# frozen_string_literal: true

module Folio
  # Concern for controllers that require session state even when cache optimization is active.
  #
  # Usage:
  #   class MyController < ApplicationController
  #     include Folio::RequiresSession
  #   end
  #
  # Or with conditional logic:
  #   class MyController < ApplicationController
  #     include Folio::RequiresSession
  #
  #     requires_session_for :quiz_actions, only: [:answer_question, :quiz_component]
  #   end
  #
  module RequiresSession
    extend ActiveSupport::Concern

    included do
      # Override cache optimization for this controller
      before_action :ensure_session_for_interactive_features

      # Track which actions require session
      class_attribute :session_required_actions, default: :all
    end

    class_methods do
      # Declare which actions require session state
      #
      # @param reason [Symbol] symbolic reason for debugging/logging
      # @param only [Array] specific actions that need session
      # @param except [Array] actions that don't need session
      #
      # Examples:
      #   requires_session_for :quiz_functionality, only: [:answer_question]
      #   requires_session_for :user_tracking, except: [:index, :show]
      #   requires_session_for :interactive_features # all actions
      #
      def requires_session_for(reason, only: nil, except: nil)
        self.session_required_actions = {
          reason: reason,
          only: only&.map(&:to_s),
          except: except&.map(&:to_s)
        }
      end
    end

    private
      def ensure_session_for_interactive_features
        return unless session_required_for_current_action?

        # Disable cache optimization session skip
        @skip_log_cookies = false
        request.session_options[:skip] = false

        # Log for debugging (non-production only)
        if !Rails.env.production? && session_required_actions.is_a?(Hash)
          reason = session_required_actions[:reason]
          Rails.logger.debug "[RequiresSession] Session required for #{controller_name}##{action_name} (#{reason})"
        end
      end

      def session_required_for_current_action?
        return true if session_required_actions == :all

        return false unless session_required_actions.is_a?(Hash)

        if session_required_actions[:only]
          session_required_actions[:only].include?(action_name)
        elsif session_required_actions[:except]
          !session_required_actions[:except].include?(action_name)
        else
          true # default to requiring session
        end
      end

      # Override cache optimization method
      def should_skip_cookies_for_cache?
        # If this controller requires session, never skip cookies
        return false if session_required_for_current_action?

        # Delegate to parent implementation
        super if defined?(super)
      end
  end
end
