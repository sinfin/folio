# frozen_string_literal: true

module Folio
  module SearchControllerBase
    extend ActiveSupport::Concern

    included do
      include Pagy::Backend
    end

    def show
      @query = ActionController::Base.helpers.sanitize(params[:q].to_s)
      @pagy, @results = pagy(PgSearch.multisearch(@query))
    end
  end
end
