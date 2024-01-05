# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Folio::ApplicationControllerBase
  helper Folio::Engine.helpers

  include Dummy::CurrentMethods
  include Folio::CacheMethods

  private
    def current_ability
      @current_ability ||= Folio::Ability.new(current_user, current_site)
    end
end
