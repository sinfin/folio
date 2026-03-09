# frozen_string_literal: true

class Folio::File::GetVideoMetadataJob < Folio::ApplicationJob
  include Folio::Shell

  queue_as :default

  # Returns { duration: Integer|nil, width: Integer|nil, height: Integer|nil }
  # Accepts local file path OR HTTP(S) URL (presigned S3 URL).
  # ffprobe streams only container headers from URLs — does NOT download the whole file.
  def perform(file_path_or_url)
    output = shell("ffprobe",
                   "-select_streams", "v:0",
                   "-show_entries", "stream=duration,width,height",
                   "-show_entries", "format=duration",
                   "-of", "json",
                   "-v", "fatal",
                   file_path_or_url)

    data = JSON.parse(output)
    stream = data.dig("streams", 0) || {}
    format_data = data.dig("format") || {}

    duration_raw = stream["duration"] || format_data["duration"]

    {
      duration: duration_raw ? duration_raw.to_f.ceil : nil,
      width: stream["width"]&.to_i,
      height: stream["height"]&.to_i,
    }
  rescue => e
    Rails.logger.error("[GetVideoMetadataJob] ffprobe failed for #{file_path_or_url.to_s.truncate(100)}: #{e.message}")
    { duration: nil, width: nil, height: nil }
  end
end
