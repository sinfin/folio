# encoding: utf-8
# frozen_string_literal: true

require 'mini_magick'

module Folio
  module Thumbnails
    extend ActiveSupport::Concern

    THUMBNAIL_ROUTE = '/thumbnail'.freeze
    MAX_WORKING_TIME = 10.minutes.to_i

    included do
      serialize :thumbnail_sizes, Hash
      before_validation :reset_thumbnails

      before_save :set_mime_type
      before_save :set_additional_data
    end

    # User w_x_h = 400x250# or similar
    #
    def thumb(w_x_h)
      fail_for_non_images

      return file.url if mime_type =~ /svg/
      thumb = thumbnail_sizes[w_x_h]

      if thumb
        if thumb[:working_since]
          if (Time.now.to_i - thumb[:working_since]) < MAX_WORKING_TIME
            return OpenStruct.new(thumb)
          else
            # run another GenerateThumbnailJob, continue
          end
        else
          return existing_thumb(thumb)
        end
      end

      url = [
        THUMBNAIL_ROUTE,
        self.id,
        w_x_h.gsub('#', '___'),
      ].join('/')

      width, height = w_x_h.scan(/\d+/).map(&:to_i)

      working_thumb = {
        uid: nil,
        signature: nil,
        url: url,
        width: width,
        height: height,
        working_since: Time.now.to_i,
      }
      self.thumbnail_sizes[w_x_h] = working_thumb
      self.save!

      GenerateThumbnailJob.perform_later(self, w_x_h)

      OpenStruct.new(working_thumb)
    end

    def existing_thumb(thumb)
      ret = OpenStruct.new(thumb)
      ret.url = Dragonfly.app.remote_url_for(ret.uid)
      ret
    end

    def landscape?
      fail_for_non_images
      file.present? && file.width >= file.height
    end

    private

      def reset_thumbnails
        fail_for_non_images
        self.thumbnail_sizes = {} if file_uid_changed?
      end

      def fail_for_non_images
        fail 'You can only thumbnail images.' unless has_attribute? 'thumbnail_sizes'
      end

      def set_mime_type
        return unless file.present?
        return unless respond_to?(:mime_type)
        self.mime_type = file.mime_type
      end

      def set_additional_data
        return unless file.present?
        return unless new_record?
        return unless self.respond_to?(:additional_data)

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

        self.additional_data ||= {
          dominant_color: hex,
          dark: dark,
        }
      end
  end
end
