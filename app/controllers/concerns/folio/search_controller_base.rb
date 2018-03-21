# frozen_string_literal: true

module Folio
  module SearchControllerBase
    extend ActiveSupport::Concern

    def show
      @query = ActionController::Base.helpers.sanitize(params[:q].to_s)
      @results = PgSearch.multisearch(@query).page(params[:page].to_i || 1)
    end
  end
end
