# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Folio::ApplicationControllerBase
  helper Folio::Engine.helpers

  before_action do
    if (params[:rmp] && account_signed_in?) || ENV['FORCE_MINI_PROFILER']
      Rack::MiniProfiler.authorize_request
    end
  end
end
