# frozen_string_literal: true

class Folio::File::GetVideoDimensionsJob < ApplicationJob
  include Folio::Shell

  queue_as :default

  def perform(file_path, human_type)
    if %w[video].include?(human_type)
      output = shell("ffprobe",
                     "-select_streams", "v:0",
                     "-show_entries", "stream=width,height",
                     "-of", "csv=s=x:p=0",
                     file_path)

      output.split("x").map(&:to_i)
    else
      fail "Uknown human_type #{human_type}"
    end
  end
end
