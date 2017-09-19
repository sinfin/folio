# frozen_string_literal: true

require_dependency 'folio/application_controller'

module Folio
  class ErrorsController < ApplicationController
    def page404
      @error_code = 404
      render 'folio/errors/show', status: @error_code
    end

    def page422
      @error_code = 422
      render 'folio/errors/show', status: @error_code
    end

    def page500
      @error_code = 500
      render 'folio/errors/show', status: @error_code
    end
  end
end
