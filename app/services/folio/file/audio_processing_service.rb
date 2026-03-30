# frozen_string_literal: true

require "json"
require "shellwords"
require "tempfile"

class Folio::File::AudioProcessingService
  include Folio::S3::Client
  include Folio::Shell

  LOW_BITRATE_WARNING_THRESHOLD_KBPS = 96
  HIGH_BITRATE_REENCODE_THRESHOLD_KBPS = 320
  TARGET_SAMPLE_RATE_HZ = 44_100
  MONO_BITRATE = "128k"
  STEREO_BITRATE = "192k"
  DERIVATIVE_ROOT = "audio".freeze
  PLAYABLE_SUBPATH = "encoded".freeze

  ALWAYS_REENCODE_MIME_TYPES = %w[
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

  DIRECT_COPY_EXTENSIONS = {
    "audio/mpeg" => "mp3",
    "audio/mp3" => "mp3",
    "audio/aac" => "aac",
    "audio/x-hx-aac-adts" => "aac",
  }.freeze

  def initialize(audio_file)
    @audio_file = audio_file
  end

  def call
    metadata = inspect_media
    mapped_metadata = build_mapped_metadata(metadata)
    playable_data = create_playable_derivative(metadata)
    artwork_image = create_or_update_artwork_image(metadata)

    persist!(
      file_metadata: mapped_metadata,
      remote_services_data: processed_remote_services_data(playable_data:, artwork_image:, mapped_metadata:),
    )

    audio_file.processing_done! if audio_file.processing?
    audio_file.reload
  end

  def extract_metadata!(force: false, save: true)
    return audio_file.file_metadata if !force && audio_file.file_metadata_extracted_at.present?

    metadata = build_mapped_metadata(inspect_media)

    persist!(file_metadata: metadata) if save

    metadata
  end

  private
    attr_reader :audio_file

    def inspect_media
      output = shell(
        "ffprobe",
        "-v", "quiet",
        "-print_format", "json",
        "-show_format",
        "-show_streams",
        audio_file.file_url_or_path
      )

      JSON.parse(output)
    end

    def processed_remote_services_data(playable_data:, artwork_image:, mapped_metadata:)
      remote_data = audio_file.remote_services_data.to_h.dup
      remote_data["playable"] = playable_data
      remote_data["artwork_image_id"] = artwork_image&.id
      remote_data["quality_warning"] = quality_warning(mapped_metadata)
      remote_data["processed_at"] = Time.current.iso8601
      remote_data
    end

    def persist!(file_metadata: nil, remote_services_data: nil)
      updates = {
        updated_at: Time.current,
      }

      if file_metadata
        updates[:file_metadata] = file_metadata
        updates[:file_metadata_extracted_at] = Time.current
      end

      updates[:remote_services_data] = remote_services_data if remote_services_data

      audio_file.update_columns(updates)
      audio_file.assign_attributes(updates)
    end

    def build_mapped_metadata(metadata)
      format_data = metadata.fetch("format", {})
      audio_stream = primary_audio_stream(metadata)
      tags = normalized_tags(format_data["tags"] || {})

      {
        "title" => tags["title"],
        "artist" => tags["artist"] || tags["album_artist"],
        "album" => tags["album"],
        "track" => tags["track"],
        "codec_name" => audio_stream&.dig("codec_name"),
        "bitrate_kbps" => bitrate_kbps(format_data:),
        "sample_rate_hz" => audio_stream&.dig("sample_rate")&.to_i,
        "channels" => audio_stream&.dig("channels")&.to_i,
        "duration_seconds" => duration_seconds(format_data:),
        "artwork_present" => artwork_stream(metadata).present?,
      }.compact
    end

    def create_playable_derivative(metadata)
      extension, content_type, ffmpeg_args = playable_derivative_plan(metadata)

      with_tempfile(extension) do |tempfile|
        shell("ffmpeg",
              "-y",
              "-i", audio_file.file_url_or_path,
              *ffmpeg_args,
              tempfile.path)

        store_derivative(tempfile:, extension:, content_type:)
      end
    end

    def playable_derivative_plan(metadata)
      if should_reencode?(metadata)
        channels = primary_audio_stream(metadata)&.dig("channels").to_i
        channel_count = channels > 1 ? 2 : 1
        bitrate = channel_count == 1 ? MONO_BITRATE : STEREO_BITRATE

        [
          "mp3",
          "audio/mpeg",
          [
            "-vn",
            "-af", "loudnorm=I=-14:LRA=11:TP=-1",
            "-acodec", "libmp3lame",
            "-ab", bitrate,
            "-ac", channel_count.to_s,
            "-ar", TARGET_SAMPLE_RATE_HZ.to_s,
          ]
        ]
      else
        [
          DIRECT_COPY_EXTENSIONS.fetch(audio_file.file_mime_type, "mp3"),
          direct_copy_content_type,
          ["-vn", "-c", "copy"]
        ]
      end
    end

    def direct_copy_content_type
      audio_file.file_mime_type.presence || "audio/mpeg"
    end

    def should_reencode?(metadata)
      return true if ALWAYS_REENCODE_MIME_TYPES.include?(audio_file.file_mime_type)

      sample_rate = primary_audio_stream(metadata)&.dig("sample_rate")&.to_i
      return true if sample_rate.positive? && sample_rate != TARGET_SAMPLE_RATE_HZ

      bitrate = bitrate_kbps(format_data: metadata.fetch("format", {}))
      bitrate.present? && bitrate > HIGH_BITRATE_REENCODE_THRESHOLD_KBPS
    end

    def quality_warning(mapped_metadata)
      bitrate = mapped_metadata["bitrate_kbps"]
      return unless bitrate.present? && bitrate < LOW_BITRATE_WARNING_THRESHOLD_KBPS

      "low_bitrate"
    end

    def store_derivative(tempfile:, extension:, content_type:)
      relative_path = derivative_relative_path(extension)

      cleanup_old_derivative!(new_path: relative_path)

      test_aware_s3_upload(s3_path: relative_path,
                           file: tempfile,
                           acl: "private")

      {
        "storage" => "s3",
        "path" => relative_path,
        "extension" => extension,
        "content_type" => content_type,
      }
    end

    def cleanup_old_derivative!(new_path:)
      old_path = audio_file.playable_file_path
      return unless old_path.present?
      return unless audio_file.playable_storage_data["storage"] == "s3"
      return if old_path == new_path

      test_aware_s3_delete(s3_path: old_path)
    end

    def derivative_relative_path(extension)
      [
        dragonfly_s3_root_path,
        DERIVATIVE_ROOT,
        PLAYABLE_SUBPATH,
        audio_file.site_id,
        audio_file.id,
        "#{audio_file.slug.presence || "audio"}-playable.#{extension}",
      ].join("/")
    end

    def create_or_update_artwork_image(metadata)
      return cleanup_missing_artwork_image! unless artwork_stream(metadata).present?

      extension = artwork_extension(metadata)

      with_tempfile(extension) do |tempfile|
        shell("ffmpeg",
              "-y",
              "-i", audio_file.file_url_or_path,
              "-an",
              "-map", "0:v:0",
              tempfile.path)

        persist_artwork_image(tempfile)
      end
    rescue StandardError => e
      Rails.logger.warn("[AudioProcessingService] artwork extraction failed for file ##{audio_file.id}: #{e.message}")
      cleanup_missing_artwork_image!
    end

    def persist_artwork_image(tempfile)
      image = audio_file.artwork_image || Folio::File::Image.new(
        site: audio_file.site,
        author: audio_file.author,
        description: audio_file.description,
        headline: [audio_file.file_name.to_s.sub(/\.[^.]+\z/, ""), "artwork"].join(" "),
      )

      image.file = tempfile
      image.save!
      image
    end

    def cleanup_missing_artwork_image!
      image = audio_file.artwork_image
      image&.destroy! if image&.persisted?
      nil
    end

    def artwork_extension(metadata)
      artwork_codec = artwork_stream(metadata)&.dig("codec_name")
      artwork_codec == "png" ? "png" : "jpg"
    end

    def artwork_stream(metadata)
      Array(metadata["streams"]).find do |stream|
        stream.dig("disposition", "attached_pic") == 1
      end
    end

    def primary_audio_stream(metadata)
      Array(metadata["streams"]).find { |stream| stream["codec_type"] == "audio" }
    end

    def duration_seconds(format_data:)
      format_data["duration"]&.to_f&.round || audio_file.file_track_duration
    end

    def bitrate_kbps(format_data:)
      bit_rate = format_data["bit_rate"]&.to_i
      return unless bit_rate&.positive?

      (bit_rate / 1000.0).round
    end

    def normalized_tags(tags)
      tags.each_with_object({}) do |(key, value), hash|
        hash[key.to_s.downcase] = value
      end
    end

    def with_tempfile(extension)
      tempfile = Tempfile.new(["folio-audio", ".#{extension}"])
      tempfile.binmode
      yield tempfile
    ensure
      tempfile&.close!
    end
end
