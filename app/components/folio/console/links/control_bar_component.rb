# frozen_string_literal: true

class Folio::Console::Links::ControlBarComponent < Folio::Console::ApplicationComponent
  URL_JSON_STRUCTURE = {
    href: { type: :string, presence: true },
    label: { type: :string, presence: false },
    target: { type: :string, presence: false },
    rel: { type: :string, presence: false },
    record_type: { type: :string, presence: false },
    record_id: { type: :number, presence: false },
  }

  def initialize(url_json: {}, href: nil)
    @url_json = url_json

    if @url_json.blank?
      @url_json = { href: }
    else
      @url_json = {}
      parsed = JSON.parse(url_json)

      %i[href label target rel record_type record_id].each do |key|
        if val = parsed[key.to_s]
          @url_json[key] = val
        end
      end
    end
  end

  def data
    stimulus_controller("f-c-links-control-bar",
                        values: {
                          href: @url_json[:href],
                        })
  end
end
