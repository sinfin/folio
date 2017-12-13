# frozen_string_literal: true

require_dependency 'folio/application_controller'

module Folio
  class ErrorsController < ApplicationController
    include ErrorsControllerBase
  end
end
