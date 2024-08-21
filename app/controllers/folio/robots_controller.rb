# frozen_string_literal: true

class Folio::RobotsController < Folio::ApplicationController
  include Folio::HasCurrentSite

  def index
    render "folio/robots/index", layout: false
  end
end
