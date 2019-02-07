# frozen_string_literal: true

class Folio::Console::SearchesController < Folio::Console::BaseController
  add_breadcrumb I18n.t('folio.console.breadcrumbs.searches'), :console_search_path

  def show
    @query = ActionController::Base.helpers.sanitize(params[:q].to_s)
    @pagy, @results = pagy(PgSearch.multisearch(@query))

    html = cell('folio/console/searches/results', @results, pagy: @pagy)

    respond_to do |format|
      format.html { render html: html, layout: 'folio/console/application' }
      format.json { render html: html, layout: false }
    end
  end
end
