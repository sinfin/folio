# encoding: utf-8
# frozen_string_literal: true

require 'mini_magick'

module Folio
  module Thumbnails
    extend ActiveSupport::Concern

    IMAGE_MIME_TYPES = %w[image/png image/jpeg image/gif image/bmp image/svg image/svg+xml]

    included do
      serialize :thumbnail_sizes, Hash
      before_validation :reset_thumbnails

      before_save :set_mime_type
      before_save :set_additional_data, if: :mime_type_image?
      before_destroy do
        ::Folio::DeleteThumbnailsJob.perform_later(self.thumbnail_sizes)
      end
    end

    class_methods do
      def immediate_thumbnails
        false
      end
    end

    # User w_x_h = 400x250# or similar
    #
    def thumb(w_x_h, quality: 90)
      fail_for_non_images
      if thumbnail_sizes[w_x_h] && thumbnail_sizes[w_x_h][:uid]
        ret = OpenStruct.new(thumbnail_sizes[w_x_h])
        ret.url = Dragonfly.app.remote_url_for(ret.uid)
        ret
      else
        if svg?
          url = file.remote_url
          width = file_width
          height = file_height
        else
          if self.class.immediate_thumbnails
            image = GenerateThumbnailJob.perform_now(self, w_x_h, quality)
            ret = OpenStruct.new(image.thumbnail_sizes[w_x_h])
            ret.url = Dragonfly.app.remote_url_for(ret.uid)
            return ret
          else
            GenerateThumbnailJob.perform_later(self, w_x_h, quality)
            url = temporary_url(w_x_h)
          end
          width, height = w_x_h.split('x').map(&:to_i)
        end
        OpenStruct.new(
          uid: nil,
          signature: nil,
          url: url,
          width: width,
          height: height,
          quality: quality
        )
      end
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
      additional_data['animated'].presence || false
    end

    private

      def reset_thumbnails
        fail_for_non_images

        if file_uid_changed?
          ::Folio::DeleteThumbnailsJob.perform_later(self.thumbnail_sizes)
          self.thumbnail_sizes = {}
        end
      end

      def fail_for_non_images
        fail 'You can only thumbnail images.' unless has_attribute?('thumbnail_sizes')
      end

      def set_mime_type
        return unless file.present?
        return unless respond_to?(:mime_type)
        self.mime_type = file.mime_type
      end

      def mime_type_image?
        IMAGE_MIME_TYPES.include? mime_type
      end

      def set_additional_data
        return unless file.present?
        return unless new_record?
        return unless self.respond_to?(:additional_data)
        return if svg?

        if gif?
          identify = ::MiniMagick::Tool::Identify.new do |i|
            i << file.path
          end
          animated = identify.split("\n").size > 1
          self.additional_data ||= {}
          self.additional_data.merge!(animated: animated)
        end

        dominant_color = ::MiniMagick::Tool::Convert.new do |convert|
          convert.merge! [
            file.path,
            '+dither',
            '-colors', '1',
            '-unique-colors',
            'txt:'
          ]
        end

        return unless dominant_color.present?

        hex = dominant_color[/#\S+/]
        rgb = hex.scan(/../).map { |color| color.to_i(16) }
        dark = rgb.sum < 3 * 255 / 2.0

        self.additional_data ||= {}

        self.additional_data.merge!(
          dominant_color: hex,
          dark: dark,
        )
      end
  end
end
