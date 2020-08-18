# frozen_string_literal: true

class Folio::SelectiveUglifier < Uglifier
  def compress(string)
    if string.start_with?("// folioSkipUglifier")
      string
    else
      super(string)
    end
  end
end
