# frozen_string_literal: true

class Folio::Console::Api::LinksController < Folio::Console::Api::BaseController
  def modal_form
    url_json_s = params.require(:url_json)

    url_json = begin
      JSON.parse(url_json_s)
    rescue StandardError
      {}
    end.symbolize_keys

    render_component_json(Folio::Console::Links::Modal::FormComponent.new(url_json:))
  end

  def control_bar
    url_json = if params[:url_json].present?
      begin
        JSON.parse(params[:url_json])
      rescue StandardError
        {}
      end
    end

    href = if url_json.blank?
      params[:href]
    end

    render_component_json(Folio::Console::Links::ControlBarComponent.new(url_json:, href:))
  end

  def value
    url_json_s = params.require(:url_json)

    url_json = begin
      JSON.parse(url_json_s)
    rescue StandardError
      {}
    end.symbolize_keys

    render_component_json(Folio::Console::Links::ValueComponent.new(url_json:, verbose: false))
  end

  def list
    render_component_json(Folio::Console::Links::Modal::ListComponent.new(filtering: true))
  end
end
