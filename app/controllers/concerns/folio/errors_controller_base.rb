# frozen_string_literal: true

module Folio
  module ErrorsControllerBase
    extend ActiveSupport::Concern

    def page400
      @error_code = 400
      render 'folio/errors/show', status: @error_code
    end

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
