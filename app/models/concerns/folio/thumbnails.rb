# frozen_string_literal: true

# rubocop:disable OpenStruct
module Folio::Thumbnails
  extend ActiveSupport::Concern

  IMAGE_MIME_TYPES = %w[image/png
                        image/jpeg
                        image/gif
                        image/bmp
                        image/svg
                        image/svg+xml]

  class_methods do
    def should_serialize_thumbnail_sizes?
      if defined?(Folio::SessionAttachment::Base) && self <= Folio::SessionAttachment::Base
        false
      else
        true
      end
    end

    def immediate_thumbnails
      false
    end
  end

  included do
    if should_serialize_thumbnail_sizes?
      serialize :thumbnail_sizes, type: Hash
    end

    before_validation :reset_thumbnails

    after_save :run_set_additional_data_job
    before_destroy :delete_thumbnails
  end

  # Use w_x_h = 400x250# or similar
  #
  def thumb(w_x_h, quality: 82, immediate: false, force: false, x: nil, y: nil, override_test_behaviour: false)
    fail_for_non_images
    return thumb_in_test_env(w_x_h, quality:) if Rails.env.test? && !override_test_behaviour

    if !force && thumbnail_sizes[w_x_h] && thumbnail_sizes[w_x_h][:uid]
      hash = thumbnail_sizes[w_x_h]

      if hash[:private]
        hash[:url] = Dragonfly.app.datastore.url_for(hash[:uid], expires: 1.hour.from_now)

        if hash[:webp_url]
          hash[:webp_url] = Dragonfly.app.datastore.url_for(hash[:webp_uid], expires: 1.hour.from_now)
        end
      end

      OpenStruct.new(hash)
    else
      if svg?
        # private svgs won't work, but that should rarely be the case
        url = file.remote_url
        width, height = get_svg_dimensions(w_x_h)
      else
        width, height = w_x_h.split("x").map(&:to_i)

        if immediate || self.class.immediate_thumbnails
          image = Folio::GenerateThumbnailJob.perform_now(self, w_x_h, quality, force:, x:, y:)
          return OpenStruct.new(image.thumbnail_sizes[w_x_h])
        else
          if thumbnail_sizes[w_x_h] && thumbnail_sizes[w_x_h][:started_generating_at] && thumbnail_sizes[w_x_h][:started_generating_at] > 5.minutes.ago
            return OpenStruct.new(thumbnail_sizes[w_x_h])
          else
            url = temporary_url(w_x_h)

            response = self.reload.with_lock do
              if !force && thumbnail_sizes[w_x_h] && thumbnail_sizes[w_x_h][:uid]
                # already added via a parallel process
                OpenStruct.new(thumbnail_sizes[w_x_h])
              else
                update(thumbnail_sizes: thumbnail_sizes.merge(w_x_h => {
                  uid: nil,
                  signature: nil,
                  x: nil,
                  y: nil,
                  url:,
                  width:,
                  height:,
                  quality:,
                  started_generating_at: Time.current,
                  temporary_url: url,
                }))

                nil
              end
            end

            return response if response

            Folio::GenerateThumbnailJob.perform_later(self, w_x_h, quality, force:, x:, y:)
          end
        end
      end

      OpenStruct.new(
        uid: nil,
        signature: nil,
        url:,
        width:,
        height:,
        x: nil,
        y: nil,
        quality:
      )
    end
  end

  def admin_thumb(immediate: false, force: false)
    thumb(Folio::Console::FileSerializer::ADMIN_THUMBNAIL_SIZE,
          immediate:,
          force:)
  end

  def lightbox_thumb(immediate: false, force: false)
    thumb(Folio::CellLightbox::LIGHTBOX_SIZE,
          immediate:,
          force:)
  end

  def thumb_in_test_env(w_x_h, quality: 90)
    width, height = w_x_h.split("x").map(&:to_i)

    OpenStruct.new(
      uid: nil,
      signature: nil,
      url: temporary_url(w_x_h),
      width:,
      height:,
      x: nil,
      y: nil,
      quality:
    )
  end

  def temporary_url(w_x_h)
    size = w_x_h.match(/\d+x?\d+/)[0]
    "https://doader.com/#{size}?image=#{id}"
  end

  def temporary_s3_url(w_x_h)
    size = w_x_h.match(/\d+x?\d+/)[0]
    "https://doader.s3.amazonaws.com/#{size}?image=#{id}"
  end

  def landscape?
    fail_for_non_images
    file.present? && file.width >= file.height
  end

  def jpg?
    file_mime_type.ends_with?("jpeg")
  end

  def svg?
    file_mime_type.include?("svg")
  end

  def gif?
    file_mime_type.include?("gif")
  end

  def animated_gif?
    return false unless gif?
    return false unless self.respond_to?(:additional_data)

    if additional_data.present?
      additional_data["animated"].present?
    else
      Folio::Files::SetAdditionalDataJob.perform_now(self)
      reload
      additional_data.present? && additional_data["animated"].present?
    end
  end

  def largest_thumb_key
    keys = thumbnail_sizes.keys
    largest_key = nil; largest_value = 0

    keys.each do |key|
      if thumbnail_sizes[key] && thumbnail_sizes[key][:height] > largest_value
        largest_key = key
        largest_value = thumbnail_sizes[key][:height]
      end
    end

    largest_key
  end

  def clear_thumbnails!
    delete_thumbnails
    save!
  end

  def recreate_all_thumbnails!
    thumbnail_sizes.each do |size, data|
      thumb(size, quality: data[:quality],
                  force: true,
                  x: data[:x],
                  y: data[:y])
    end
  end

  def development_safe_file(logger = nil)
    if persisted? && Rails.env.development? && ENV["DRAGONFLY_PRODUCTION_S3_URL_BASE"]
      logger ||= Rails.logger
      datastore = file.app.datastore
      content, _meta = datastore.read(file_uid)

      if content.nil?
        development_safe_file_debug(logger, "Missing S3 file.")

        joiner = ENV["DRAGONFLY_PRODUCTION_S3_URL_BASE"].ends_with?("/") ? "" : "/"
        production_s3_url = "#{ENV["DRAGONFLY_PRODUCTION_S3_URL_BASE"]}#{joiner}#{file_uid}"

        headers = { "Content-Type" => file_mime_type }
        default_meta = {
          "name" => file_name,
          "model_class" => self.class.to_s,
          "model_attachment" => "file",
        }

        begin
          development_safe_file_debug(logger, "Trying production S3 file - #{production_s3_url}")

          open(production_s3_url) do |s3_file|
            datastore.storage.put_object(datastore.bucket_name,
                                         datastore.send(:full_path, file_uid),
                                         s3_file,
                                         datastore.send(:full_storage_headers, headers, default_meta))
          end

          development_safe_file_debug(logger, "Stored production S3 file - #{production_s3_url} - to development S3 - #{file.remote_url}")

          file
        rescue StandardError
          development_safe_file_debug(logger, "Failed to fetch production S3 file. Using placeholder.")

          placeholder_url = "https://via.placeholder.com/1000x750.png?text=Missing+production+image"

          open(placeholder_url) do |s3_file|
            datastore.storage.put_object(datastore.bucket_name,
                                         datastore.send(:full_path, file_uid),
                                         s3_file,
                                         datastore.send(:full_storage_headers, headers, default_meta))
          end

          development_safe_file_debug(logger, "Stored placeholder S3 file - #{placeholder_url} - to development S3 - #{file.remote_url}")

          file
        rescue StandardError
          fail "Missing file_uid - #{file_uid} - did not find any at production either (#{production_s3_url}), couldn't fetch via placeholder.com."
        end
      else
        file
      end
    end
  end

  def thumbnailable?
    true
  end

  private
    def reset_thumbnails
      delete_thumbnails if file_uid_changed? && has_attribute?("thumbnail_sizes")
    end

    def delete_thumbnails
      if self.try(:thumbnail_sizes).present?
        Folio::DeleteThumbnailsJob.perform_later(self.thumbnail_sizes)
        self.thumbnail_sizes = {}
      end
    end

    def fail_for_non_images
      fail "You can only thumbnail images." unless has_attribute?("thumbnail_sizes") && thumbnailable?
    end

    def file_mime_type_image?
      IMAGE_MIME_TYPES.include? file_mime_type
    end

    def run_set_additional_data_job
      return unless file.present?
      return unless persisted?
      return unless file_mime_type_image?
      return unless saved_change_to_file_mime_type?
      return unless self.respond_to?(:additional_data)
      return if additional_data?
      return if svg?

      Folio::Files::SetAdditionalDataJob.perform_later(self)
    end

    def development_safe_file_debug(logger, msg)
      logger.tagged(self.class.to_s, "development_safe_file", self.id) do
        logger.info(msg)
      end
    end

    def get_svg_dimensions(w_x_h)
      original_width = file.width.to_f
      original_height = file.height.to_f
      return [0, 0] if !original_width || !original_height

      if w_x_h.include?("#")
        return w_x_h.split("x", 2).map { |p| p.to_i }
      elsif w_x_h.match?(/\d+x\d+/)
        max_width, max_height = w_x_h.split("x", 2).map { |p| p.to_f }
      elsif matches = w_x_h.match(/(\d+)x/)
        max_width = matches[1].to_f
        max_height = 9999.0
      elsif matches = w_x_h.match(/x(\d+)/)
        max_width = 9999.0
        max_height = matches[1].to_f
      else
        return [0, 0]
      end

      return [0, 0] if original_width == 0 || original_height == 0

      max_ratio = max_width / max_height
      original_ratio = original_width / original_height

      if original_ratio > max_ratio
        target_width = max_width.to_i
        target_height = (max_width / original_width * original_height).ceil.to_i
      else
        target_height = max_height.to_i
        target_width = (max_height / original_height * original_width).ceil.to_i
      end

      [target_width, target_height]
    end
end
# rubocop:enable OpenStruct
