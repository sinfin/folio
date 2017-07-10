# frozen_string_literal: true

require_dependency 'folio/application_controller'

module Folio
  class Devise::BaseController < ApplicationController
    layout 'folio/console'
  end
end
