# frozen_string_literal: true

module Folio::Devise::CrossdomainController
  extend ActiveSupport::Concern

  included do
    before_action :handle_crossdomain_devise
  end

  private
    def handle_crossdomain_devise
      return @devise_crossdomain_result if @devise_crossdomain_result

      @devise_crossdomain_result = Folio::Devise::Crossdomain.new(request:,
                                                                  session:,
                                                                  current_site:,
                                                                  current_user:,
                                                                  controller_name:,
                                                                  action_name:,
                                                                  devise_controller: try(:devise_controller?)).handle_before_action!

      case @devise_crossdomain_result.action
      when :noop
        return
      end

      @devise_crossdomain_result
    end

  protected
    # override devise signed in check - redirect to source site if needed
    def require_no_authentication
      result = handle_crossdomain_devise
      super if result.action == :noop
    end
end
