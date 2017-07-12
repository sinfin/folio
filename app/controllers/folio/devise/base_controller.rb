# frozen_string_literal: true

require_dependency 'folio/application_controller'

module Folio
  class Devise::BaseController < ApplicationController
    layout 'folio/console/application'

    before_action do
      @devise = true
    end
  end
end
