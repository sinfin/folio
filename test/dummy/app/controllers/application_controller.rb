# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Folio::ApplicationControllerBase
  helper Folio::Engine.helpers

  include Dummy::CacheKeys
  include Dummy::CurrentMethods
  include Folio::CacheMethods

  private
    def current_ability # so CanCanCan can use it
      @current_ability ||= ::Folio::Current.ability
    end
end
