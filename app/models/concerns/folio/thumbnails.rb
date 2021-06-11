# frozen_string_literal: true

require "mini_magick"

module Folio::Thumbnails
  extend ActiveSupport::Concern

  IMAGE_MIME_TYPES = %w[image/png
                        image/jpeg
                        image/gif
                        image/bmp
                        image/svg
                        image/svg+xml]

  included do
    serialize :thumbnail_sizes, Hash
    before_validation :reset_thumbnails

    after_save :run_set_additional_data_job
    before_destroy :delete_thumbnails
  end

  class_methods do
    def immediate_thumbnails
      false
    end
  end

  # Use w_x_h = 400x250# or similar
  #
  def thumb(w_x_h, quality: 82, immediate: false, force: false, x: nil, y: nil)
    fail_for_non_images
    return thumb_in_test_env(w_x_h, quality: quality) if Rails.env.test?

    if !force && thumbnail_sizes[w_x_h] && thumbnail_sizes[w_x_h][:uid]
      OpenStruct.new(thumbnail_sizes[w_x_h])
    else
      if svg?
        url = file.remote_url
        width = file_width
        height = file_height
      else
        if immediate || self.class.immediate_thumbnails
          image = Folio::GenerateThumbnailJob.perform_now(self, w_x_h, quality, force: force, x: x, y: y)
          return OpenStruct.new(image.thumbnail_sizes[w_x_h])
        else
          Folio::GenerateThumbnailJob.perform_later(self, w_x_h, quality, force: force, x: x, y: y)
          url = temporary_url(w_x_h)
        end
        width, height = w_x_h.split("x").map(&:to_i)
      end
      OpenStruct.new(
        uid: nil,
        signature: nil,
        url: url,
        width: width,
        height: height,
        x: nil,
        y: nil,
        quality: quality
      )
    end
  end

  def admin_thumb(immediate: false, force: false)
    thumb(Folio::Console::FileSerializer::ADMIN_THUMBNAIL_SIZE,
          immediate: immediate,
          force: force)
  end

  def thumb_in_test_env(w_x_h, quality: 90)
    width, height = w_x_h.split("x").map(&:to_i)

    OpenStruct.new(
      uid: nil,
      signature: nil,
      url: temporary_url(w_x_h),
      width: width,
      height: height,
      x: nil,
      y: nil,
      quality: quality
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

  def svg?
    mime_type =~ /svg/
  end

  def gif?
    mime_type =~ /gif/
  end

  def animated_gif?
    return false unless gif?
    return false unless self.respond_to?(:additional_data)
    additional_data["animated"].presence || false
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

  private
    def reset_thumbnails
      fail_for_non_images

      delete_thumbnails if file_uid_changed?
    end

    def delete_thumbnails
      fail_for_non_images

      if self.thumbnail_sizes.present?
        Folio::DeleteThumbnailsJob.perform_later(self.thumbnail_sizes)
        self.thumbnail_sizes = {}
      end
    end

    def fail_for_non_images
      fail "You can only thumbnail images." unless has_attribute?("thumbnail_sizes")
    end

    def mime_type_image?
      IMAGE_MIME_TYPES.include? mime_type
    end

    def run_set_additional_data_job
      return unless file.present?
      return unless persisted?
      return unless mime_type_image?
      return unless self.respond_to?(:additional_data)
      return if additional_data?
      return if svg?

      Folio::Files::SetAdditionalDataJob.perform_later(self)
    end
end
