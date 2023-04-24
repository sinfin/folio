# frozen_string_literal: true

class Folio::File::GetFileTrackDurationJob < ApplicationJob
  include Folio::Shell

  queue_as :default

  def perform(file_path, human_type)
    if %w[audio video].include?(human_type)
      output = shell("ffprobe",
                     "-show_entries", "stream=duration",
                     "-of", "compact=p=0:nk=1",
                     "-v", "fatal",
                     file_path)

      output.split("\n")[0].to_f.ceil
    else
      fail "Uknown human_type #{human_type}"
    end
  end
end
