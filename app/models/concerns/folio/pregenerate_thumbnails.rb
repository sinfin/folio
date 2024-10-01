# encoding: utf-8
# frozen_string_literal: true

module Folio::PregenerateThumbnails
  extend ActiveSupport::Concern

  included do
    after_save :pregenerate_thumbnails
  end

  def check_pregenerated_thumbnails
    h = {
      versions: [],
      missing: [],
      loading: [],
      present: [],
    }

    return h unless file.respond_to?(:thumb)
    return h unless try(:placement)

    versions = placement.class.try(:pregenerated_thumbnails)
    return h if versions.blank?

    if versions.is_a?(Hash)
      if versions[self.class.to_s].present?
        collection = versions[self.class.to_s].uniq
      else
        collection = []
      end
    elsif versions.is_a?(Array)
      collection = versions.uniq
    else
      collection = []
    end

    collection << Folio::Console::FileSerializer::ADMIN_THUMBNAIL_SIZE

    collection.each do |version|
      h[:versions] << version
      thumb = file.thumbnail_sizes[version]

      if thumb.blank?
        h[:missing] << version
      else
        url = thumb[:url]
        webp_url = thumb[:webp_url]

        if url.blank? || webp_url.blank?
          h[:missing] << version
        elsif url.include?("doader.") || webp_url.include?("doader.")
          h[:loading] << version
        else
          h[:present] << version
        end
      end
    end

    h
  end

  def check_pregenerated_thumbnails!
    h = check_pregenerated_thumbnails

    if h[:missing].present? || h[:loading].present?
      all_invalid = h[:missing] + h[:loading]
      file.update!(thumbnail_sizes: file.thumbnail_sizes.without(*all_invalid))

      Rails.logger.info("Folio::PregenerateThumbnails: #{self.class} #{id} for \"#{placement.class} - #{placement.id} - #{placement.to_label}\" recreating missing thumbnail sizes - #{all_invalid.join(', ')}.")

      all_invalid.each do |variant|
        file.thumb(variant)
      end
    end

    h
  end

  private
    def pregenerate_thumbnails
      return unless file.respond_to?(:thumb)
      return if Rails.env.test? && !file.try(:additional_data).try(:[], "generate_thumbnails_in_test")

      # admin thumbnail
      file.thumb(Folio::Console::FileSerializer::ADMIN_THUMBNAIL_SIZE)

      if is_a?(Folio::FilePlacement::OgImage)
        file.thumb(Folio::OG_IMAGE_DIMENSIONS)
      end

      # public page thumbnails
      return unless respond_to?(:placement)
      versions = placement.class.try(:pregenerated_thumbnails)
      return if versions.blank?

      if versions.is_a?(Hash)
        if versions[self.class.to_s].present?
          collection = versions[self.class.to_s].uniq
        else
          collection = nil
        end
      elsif versions.is_a?(Array)
        collection = versions.uniq
      else
        collection = nil
      end

      if collection.present?
        collection.each do |version, quality|
          if quality.present?
            file.thumb(version, quality:)
          else
            file.thumb(version)
          end
        end
      end
    end
end
