# frozen_string_literal: true

module Folio::Accounts::DeviseControllerBase
  extend ActiveSupport::Concern
  include Folio::Devise::CrossdomainController

  included do
    layout "folio/console/devise"
  end

  protected
    # override devise signed in check - redirect to source site if needed
    def require_no_authentication
      result = handle_crossdomain_devise
      super if result && result.action == :noop
    end
end
