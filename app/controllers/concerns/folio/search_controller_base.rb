# frozen_string_literal: true

module Folio::SearchControllerBase
  extend ActiveSupport::Concern

  included do
    include Pagy::Method
  end

  def show
    @query = ActionController::Base.helpers.sanitize(params[:q].to_s)
    @pagy, @results = pagy(:offset, PgSearch.multisearch(@query))
  end
end
