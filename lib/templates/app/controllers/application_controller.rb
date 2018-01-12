# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Folio::ApplicationControllerBase
  helper Folio::Engine.helpers
end
