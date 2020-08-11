# encoding: utf-8
# frozen_string_literal: true

module Folio::PregenerateThumbnails
  extend ActiveSupport::Concern

  included do
    after_save :pregenerate_thumbnails
  end

  private
    def pregenerate_thumbnails
      return if Rails.env.test?
      return unless file.respond_to?(:thumb)

      # admin thumbnail
      file.thumb(Folio::Console::FileSerializer::ADMIN_THUMBNAIL_SIZE)

      # public page thumbnails
      return unless respond_to?(:placement)
      versions = placement.class.try(:pregenerated_thumbnails)
      return if versions.blank?
      versions.uniq.each do |version, quality|
        if quality.present?
          file.thumb(version, quality: quality)
        else
          file.thumb(version)
        end
      end
    end
end
