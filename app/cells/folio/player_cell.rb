# frozen_string_literal: true

class Folio::PlayerCell < ApplicationCell
  def data
    {
      "controller" => "f-player",
      "file" => Folio::FileSerializer.new(model)
                                     .serializable_hash[:data]
                                     .to_json,
      "f-player-show-form-controls-value" => options[:show_form_controls] ? "true" : "false",
    }
  end
end
