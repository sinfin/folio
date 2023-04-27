# frozen_string_literal: true

class Folio::Console::File::Picker::DocumentCell < Folio::ConsoleCell
  def data
    {
      "controller" => "f-c-file-picker-document",
      "file" => Folio::Console::FileSerializer.new(model)
                                              .serializable_hash[:data]
                                              .to_json,
    }
  end
end
