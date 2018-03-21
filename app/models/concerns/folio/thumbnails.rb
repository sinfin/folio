# encoding: utf-8
# frozen_string_literal: true

require 'mini_magick'

module Folio
  module Thumbnails
    module Base
      extend ActiveSupport::Concern

      included do
        serialize :thumbnail_sizes, Hash
        before_validation :reset_thumbnails

        before_save :set_mime_type
        before_destroy do
          Folio::DeleteThumbnailsJob.perform_later(self.thumbnail_sizes)
        end
      end

      # User w_x_h = 400x250# or similar
      #
      def thumb(w_x_h)
        fail_for_non_images
        if thumbnail_sizes[w_x_h]
          ret = OpenStruct.new(thumbnail_sizes[w_x_h])
          ret.url = Dragonfly.app.remote_url_for(ret.uid)
          ret
        else
          if mime_type =~ /svg/
            url = file.url
          else
            GenerateThumbnailJob.perform_later(self, w_x_h)
            url = temporary_url(w_x_h)
          end
          sizes = w_x_h.split('x')
          OpenStruct.new(
            uid: nil,
            signature: nil,
            url: url,
            width: sizes[0].to_i,
            height: sizes[1].to_i
          )
        end
      end

      def temporary_url(w_x_h)
        size = w_x_h.match(/\d+x?\d+/)[0]
        "http://doader.com/#{size}?image=#{id}"
      end

      def temporary_s3_url(w_x_h)
        size = w_x_h.match(/\d+x?\d+/)[0]
        "https://doader.s3.amazonaws.com/#{size}?image=#{id}"
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
    end

    module Image
      extend ActiveSupport::Concern
      include Base

      included do
        before_save :set_additional_data
      end

      def landscape?
        fail_for_non_images
        file.present? && file.width >= file.height
      end

      private
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
end
