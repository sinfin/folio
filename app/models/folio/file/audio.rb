# frozen_string_literal: true

class Folio::File::Audio < Folio::File
  validate_file_format %w[audio/mpeg audio/aac audio/x-hx-aac-adts]

  def self.human_type
    "audio"
  end
end
