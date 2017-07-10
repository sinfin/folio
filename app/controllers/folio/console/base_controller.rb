# frozen_string_literal: true

require_dependency 'folio/application_controller'

module Folio
  class Console::BaseController < ApplicationController
    before_action :authenticate_account!
    layout 'folio/console'
  end
end
