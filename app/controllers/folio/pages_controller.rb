# frozen_string_literal: true

require_dependency 'folio/application_controller'

module Folio
  class PagesController < BaseController
    include PagesControllerBase
  end
end
