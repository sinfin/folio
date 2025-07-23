# frozen_string_literal: true

class Folio::Console::Api::LinksController < Folio::Console::Api::BaseController
  def modal_form
    url_json_s = params.require(:url_json)

    url_json = begin
      JSON.parse(url_json_s)
    rescue StandardError
      {}
    end.symbolize_keys

    json = params[:json] != false && params[:json] != "false"
    absolute_urls = params[:absolute_urls] == true || params[:absolute_urls] == "true"

    render_component_json(Folio::Console::Links::Modal::FormComponent.new(url_json:,
                                                                          json:,
                                                                          absolute_urls:,
                                                                          disable_label: params[:disable_label].to_s == "true",
                                                                          preferred_label: params[:preferred_label].presence))
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

    json = params[:json] != false && params[:json] != "false"
    absolute_urls = params[:absolute_urls] == true || params[:absolute_urls] == "true"

    render_component_json(Folio::Console::Links::ControlBarComponent.new(url_json:,
                                                                         href:,
                                                                         json:,
                                                                         absolute_urls:))
  end

  def value
    url_json_s = params.require(:url_json)

    url_json = begin
      JSON.parse(url_json_s)
    rescue StandardError
      {}
    end.symbolize_keys

    json = params[:json] != false && params[:json] != "false"

    render_component_json(Folio::Console::Links::ValueComponent.new(url_json:,
                                                                    verbose: false,
                                                                    json:))
  end

  def list
    absolute_urls = params[:absolute_urls] == true || params[:absolute_urls] == "true"

    render_component_json(Folio::Console::Links::Modal::ListComponent.new(filtering: true,
                                                                          absolute_urls:))
  end
end
