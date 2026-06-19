# frozen_string_literal: true

class Folio::File::Audio < Folio::File
  include Folio::S3::Client

  ACCEPTED_FILE_FORMATS = %w[
    audio/mpeg
    audio/mp3
    audio/aac
    audio/x-hx-aac-adts
    audio/mp4
    audio/x-m4a
    audio/wav
    audio/x-wav
    audio/vnd.wave
    audio/flac
    audio/x-flac
    audio/ogg
    application/ogg
  ].freeze

  validate_file_format ACCEPTED_FILE_FORMATS

  def mapped_metadata
    @mapped_metadata ||= if file_metadata.present?
      Folio::Metadata::AudioFieldMapper.map_metadata(file_metadata)
    else
      {}
    end
  end

  def artwork_image
    return @artwork_image if defined?(@artwork_image)

    image_id = remote_services_data.to_h["artwork_image_id"]
    @artwork_image = image_id.present? ? Folio::File::Image.find_by(id: image_id) : nil
  end

  def artwork_image_placement
    return unless artwork_image.present?

    Folio::FilePlacement::Cover.new(file: artwork_image)
  end

  def playable_storage_data
    remote_services_data.to_h["playable"].to_h
  end

  def playable_file_path
    playable_storage_data["path"]
  end

  def playable_content_type
    playable_storage_data["content_type"].presence || file_mime_type
  end

  def playable_extension
    playable_storage_data["extension"].presence || file_extension.to_s
  end

  def playable_download_url(expires_in: 15.minutes.to_i)
    return unless playable_file_path.present?

    test_aware_presign_url(s3_path: playable_file_path,
                           method_name: :get_object,
                           expires_in:)
  end

  def player_source_url(expires_in: 15.minutes.to_i)
    playable_download_url(expires_in:) || original_download_url(expires_in:)
  end

  def player_source_mime_type
    playable_file_path.present? ? playable_content_type : file_mime_type
  end

  def low_quality_source?
    remote_services_data.to_h["quality_warning"] == "low_bitrate"
  end

  def private?
    true
  end

  def self.human_type
    "audio"
  end

  def extract_metadata!(force: false, user_id: nil, save: true)
    Folio::File::AudioProcessingService.new(self).extract_metadata!(force:, save:)
  end

  def process_attached_file
    Folio::File::ProcessAudioJob.perform_later(self)
  end

  def formatted_duration
    return nil if file_track_duration.nil?

    total = file_track_duration.to_i
    h = total / 3600
    m = (total % 3600) / 60
    s = total % 60

    if h > 0
      format("%d:%02d:%02d", h, m, s)
    else
      format("%d:%02d", m, s)
    end
  end

  private
    def original_download_url(expires_in:)
      Folio::S3.url_rewrite(file.remote_url(expires: expires_in.seconds.from_now))
    end
end
