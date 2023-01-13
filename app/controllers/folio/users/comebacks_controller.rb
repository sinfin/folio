# frozen_string_literal: true

class Folio::Users::ComebacksController < ApplicationController
  include Folio::Users::DeviseControllerBase

  def show
    store_location_for(:user, landing_param)
    redirect_to to_param
  end

  private
    def permitted_params
      params.permit(:landing,
                    :to)
    end

    def landing_param
      permitted_params[:landing] || fallback
    end

    def to_param
      permitted_params[:to]
    end

    def fallback
      if loc = stored_location_for(:user)
        loc
      else
        request.referrer
      end
    end
end
