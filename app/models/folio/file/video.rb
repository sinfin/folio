# frozen_string_literal: true

class Folio::File::Video < Folio::File
  include Folio::File::Video::HasSubtitles

  validate_file_format %w[video/mp4 video/webm video/quicktime video/x-m4v]

  def console_show_additional_fields
    additional_fields = {}

    self.class.enabled_subtitle_languages.each do |lang|
      additional_fields[:"subtitles_#{lang}_text"] = { type: :text }
    end

    additional_fields
  end

  def thumbnailable?
    true
  end

  def video_poster_url
    nil # override in provider concerns to return a static thumbnail image URL
  end

  def self.human_type
    "video"
  end
end
