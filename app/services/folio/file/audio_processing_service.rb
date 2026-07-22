# frozen_string_literal: true

require "json"
require "tempfile"

class Folio::File::AudioProcessingService
  include Folio::S3::Client
  include Folio::Shell

  LOW_BITRATE_WARNING_THRESHOLD_KBPS = 96
  HIGH_BITRATE_REENCODE_THRESHOLD_KBPS = 320
  TARGET_SAMPLE_RATE_HZ = 44_100
  MONO_BITRATE = "128k"
  STEREO_BITRATE = "192k"
  WAVEFORM_POINT_COUNT = 200
  WAVEFORM_ANALYSIS_SAMPLE_RATE_HZ = 11_025
  DERIVATIVE_ROOT = "audio"
  PLAYABLE_SUBPATH = "encoded"

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
    old_playable_path = audio_file.playable_file_path
    old_playable_storage = audio_file.playable_storage_data["storage"]
    metadata = inspect_media
    mapped_metadata = build_mapped_metadata(metadata)
    playable_data = create_playable_derivative(metadata)
    waveform_payload = safely_generate_waveform_payload(playable_data:, mapped_metadata:)
    seed_artwork_cover(metadata)

    persist!(
      file_metadata: mapped_metadata,
      remote_services_data: processed_remote_services_data(playable_data:, mapped_metadata:, waveform_payload:),
    )

    audio_file.processing_done! if audio_file.processing?
    cleanup_old_derivative!(old_path: old_playable_path,
                            old_storage: old_playable_storage,
                            new_path: playable_data["path"])
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

    def processed_remote_services_data(playable_data:, mapped_metadata:, waveform_payload:)
      remote_data = audio_file.remote_services_data.to_h.dup
      remote_data["playable"] = playable_data
      if waveform_payload.present?
        remote_data["waveform"] = waveform_payload
      else
        remote_data.delete("waveform")
      end
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

      if file_metadata
        mapped = Folio::Metadata::AudioFieldMapper.map_metadata(file_metadata)
        Folio::Metadata::AudioFieldMapper.update_database_fields(audio_file, mapped)
      end
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

    def safely_generate_waveform_payload(playable_data:, mapped_metadata:)
      generate_waveform_payload(playable_data:, mapped_metadata:)
    rescue StandardError => e
      Rails.logger.warn("[AudioProcessingService] waveform generation failed for file ##{audio_file.id}: #{e.message}")
      nil
    end

    def generate_waveform_payload(playable_data:, mapped_metadata:)
      peaks = nil

      with_waveform_source(playable_data) do |source_path|
        with_tempfile("raw") do |tempfile|
          shell("ffmpeg",
                "-y",
                "-i", source_path,
                "-vn",
                "-ac", "1",
                "-ar", WAVEFORM_ANALYSIS_SAMPLE_RATE_HZ.to_s,
                "-f", "s16le",
                "-acodec", "pcm_s16le",
                tempfile.path)

          peaks = waveform_peaks_from_file(tempfile.path)
        end
      end

      {
        "peaks" => peaks,
      }
    end

    def with_waveform_source(playable_data)
      if playable_data["storage"] == "s3" && playable_data["path"].present?
        with_tempfile(playable_data["extension"].presence || "audio") do |tempfile|
          test_aware_download_from_s3(s3_path: playable_data["path"], local_path: tempfile.path)
          yield tempfile.path
        end
      else
        yield audio_file.file_url_or_path
      end
    end

    def waveform_peaks_from_file(path)
      samples = File.binread(path).unpack("s<*")
      return [] if samples.empty?

      bucket_peaks = Array.new(WAVEFORM_POINT_COUNT, 0)
      total_samples = samples.size

      samples.each_with_index do |sample, index|
        bucket_index = index * WAVEFORM_POINT_COUNT / total_samples
        peak = sample.abs

        bucket_peaks[bucket_index] = peak if peak > bucket_peaks[bucket_index]
      end

      normalize_waveform_peaks(bucket_peaks)
    end

    def normalize_waveform_peaks(bucket_peaks)
      max_peak = bucket_peaks.max
      return Array.new(WAVEFORM_POINT_COUNT, 0.0) unless max_peak&.positive?

      bucket_peaks.map do |peak|
        normalized = (peak / max_peak.to_f).clamp(0.0, 1.0)

        Math.sqrt(normalized).round(3)
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

    def cleanup_old_derivative!(old_path:, old_storage:, new_path:)
      return unless old_path.present?
      return unless old_storage == "s3"
      return if old_path == new_path

      test_aware_s3_delete(s3_path: old_path)
    rescue StandardError => e
      Rails.logger.warn("[AudioProcessingService] old derivative cleanup failed for file ##{audio_file.id}: #{e.message}")
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

    # The artwork placement is only seeded from the embedded ID3 artwork on
    # the first processing run — the console owns it afterwards, so neither
    # a reprocess nor a file replacement may resurrect a removed artwork.
    def seed_artwork_cover(metadata)
      return audio_file.artwork_cover if audio_file.artwork_cover_placement.present?
      return nil if audio_file.remote_services_data.to_h["processed_at"].present?
      return nil unless artwork_stream(metadata).present?

      extension = artwork_extension(metadata)

      with_tempfile(extension) do |tempfile|
        shell("ffmpeg",
              "-y",
              "-i", audio_file.file_url_or_path,
              "-an",
              "-map", "0:v:0",
              tempfile.path)

        Folio::File::Image.transaction do
          persist_artwork_image(tempfile).tap do |image|
            audio_file.create_artwork_cover_placement!(file: image)
          end
        end
      end
    rescue StandardError => e
      Rails.logger.warn("[AudioProcessingService] artwork extraction failed for file ##{audio_file.id}: #{e.message}")
      nil
    end

    def persist_artwork_image(tempfile)
      image = Folio::File::Image.new(
        site: audio_file.site,
        author: audio_file.author,
        description: audio_file.description,
        headline: [audio_file.file_name.to_s.sub(/\.[^.]+\z/, ""), "artwork"].join(" "),
      )

      image.file = tempfile
      image.save!
      image
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
      tags.transform_keys do |key|
        key.to_s.downcase
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
