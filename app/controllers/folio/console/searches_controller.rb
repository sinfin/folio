# frozen_string_literal: true

class Folio::Console::SearchesController < Folio::Console::BaseController
  add_breadcrumb I18n.t("folio.console.breadcrumbs.searches"), :console_search_path

  def show
    authorize! :multisearch_console, current_site

    @query = ActionController::Base.helpers.sanitize(params[:q].to_s)

    respond_to do |format|
      format.html { render html:, layout: "folio/console/application" }
      format.json { render html: html(js: true), layout: false }
    end
  end

  private
    def html(js: false)
      results = PgSearch.multisearch(@query)
      if js
        @results = results.limit(10)
      else
        @pagy, @results = pagy(results)
      end

      cell("folio/console/searches/results", @results, pagy: @pagy)
    end
end
