# frozen_string_literal: true

class Folio::Users::ComebacksController < ApplicationController
  include Folio::Users::DeviseControllerBase

  def show
    store_location_for(:user, landing_param)
    # Crawlers request the path without the query string; follow only local URLs.
    redirect_to url_from(to_param) || main_app.root_path
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
