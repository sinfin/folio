# frozen_string_literal: true

class Folio::RobotsController < Folio::ApplicationController
  def index
    render "folio/robots/index", layout: false, content_type: "text/plain"
  end
end
