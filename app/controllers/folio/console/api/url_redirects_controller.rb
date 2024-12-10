# frozen_string_literal: true

class Folio::Console::Api::UrlRedirectsController < Folio::Console::Api::BaseController
  folio_console_controller_for "Folio::UrlRedirect"

  def demo
    url_redirect = if params[:id].present?
      Folio::UrlRedirect.by_site(Folio::Current.site).find_by_id(params[:id])
    end

    url_redirect ||= Folio::UrlRedirect.new
    url_redirect.assign_attributes(url_redirect_params)

    render_component_json(Folio::Console::UrlRedirects::Fields::DemoComponent.new(url_redirect:))
  end

  private
    def url_redirect_params
      params.require(:url_redirect)
            .permit(*(@klass.column_names - %w[id site_id]))
    end
end
