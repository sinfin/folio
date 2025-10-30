# frozen_string_literal: true

class Folio::File::GetVideoDimensionsJob < Folio::ApplicationJob
  include Folio::Shell

  queue_as :default

  if respond_to?(:sidekiq_options)
    sidekiq_options lock: :until_and_while_executing,
                    lock_ttl: 10.minutes.to_i,
                    on_conflict: {
                      client: :log,
                      server: :raise
                    }
  end

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
