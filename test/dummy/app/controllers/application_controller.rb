# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Folio::ApplicationControllerBase
  helper Folio::Engine.helpers

  include Dummy::CurrentMethods
  include Folio::CacheMethods
end
