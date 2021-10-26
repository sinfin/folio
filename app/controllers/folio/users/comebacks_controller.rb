# frozen_string_literal: true

class Folio::Users::ComebacksController < ApplicationController
  include Folio::Users::DeviseControllerBase

  def show
    store_location_for(:user, landing_param)
    redirect_to to_param
  end

  private
    def landing_param
      params.permit(:landing)[:landing] || fallback
    end

    def to_param
      params.permit(:to)[:to]
    end

    def fallback
      if loc = stored_location_for(:user)
        loc
      else
        request.referrer
      end
    end
end
