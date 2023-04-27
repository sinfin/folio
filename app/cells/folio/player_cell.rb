# frozen_string_literal: true

class Folio::PlayerCell < ApplicationCell
  def data
    {
      "controller" => "f-player",
      "file" => serializer.new(model)
                          .serializable_hash[:data]
                          .to_json,
      "f-player-show-form-controls-value" => options[:show_form_controls] ? "true" : "false",
    }
  end

  def serializer
    if options[:show_form_controls]
      Folio::Console::FileSerializer
    else
      Folio::FileSerializer
    end
  end
end
