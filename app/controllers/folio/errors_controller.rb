# frozen_string_literal: true

require_dependency 'folio/application_controller'

module Folio
  class ErrorsController < ApplicationController
    def not_found
      @status = 404
      render(status: 404)
    end

    def internal_server_error
      @status = 500
      render(status: 500)
    end
  end
end
