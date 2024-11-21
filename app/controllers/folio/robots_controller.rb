# frozen_string_literal: true

class Folio::RobotsController < Folio::ApplicationController
  def index
    render "folio/robots/index", layout: false
  end
end
