# frozen_string_literal: true

class Folio::PlayerCell < ApplicationCell
  def data
    {
      controller: "f-player",
      file: Folio::FileSerializer.new(model)
                                 .serializable_hash[:data]
                                 .to_json
    }
  end
end
