# frozen_string_literal: true

class Folio::Console::Links::ControlBarComponent < Folio::Console::ApplicationComponent
  def initialize(url_json: {}, href: nil, json: true, absolute_urls: false, default_custom_url: false, disabled_button: true)
    @url_json = url_json

    @json = json
    @absolute_urls = absolute_urls
    @default_custom_url = default_custom_url
    @disabled_button = disabled_button

    if @url_json.blank?
      @url_json = { href: }
    else
      @url_json = {}

      %i[href label target rel record_type record_id].each do |key|
        if val = url_json[key.to_s]
          @url_json[key] = val
        end
      end
    end
  end

  def data
    stimulus_controller("f-c-links-control-bar",
                        values: {
                          href: @url_json[:href],
                          json: @json,
                          absolute_urls: @absolute_urls,
                          default_custom_url: @default_custom_url,
                          disabled_button: @disabled_button
                        })
  end
end
