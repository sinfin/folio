# frozen_string_literal: true

class Folio::Console::File::Picker::ThumbCell < Folio::ConsoleCell
  def data
    {
      "controller" => "f-c-file-picker-thumb",
      "file" => Folio::Console::FileSerializer.new(model)
                                              .serializable_hash[:data]
                                              .to_json,
    }
  end
end
