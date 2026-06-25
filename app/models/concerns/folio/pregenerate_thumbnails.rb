# encoding: utf-8
# frozen_string_literal: true

module Folio::PregenerateThumbnails
  extend ActiveSupport::Concern

  included do
    after_save_commit :pregenerate_thumbnails
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

    collection = [Folio::Console::FileSerializer::ADMIN_THUMBNAIL_SIZE] + pregenerated_thumbnail_variants(versions)

    collection.each do |variant|
      version = pregenerated_thumbnail_version(variant)

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
    pregenerated_thumbnail_variants(placement.class.try(:pregenerated_thumbnails)).each do |variant|
      version = pregenerated_thumbnail_version(variant)
      quality = pregenerated_thumbnail_quality(variant)

      if quality.present?
        file.thumb(version, quality:)
      else
        file.thumb(version)
      end
    end
  end

  private
    def pregenerated_thumbnail_variants(versions)
      collection = case versions
                   when Hash
                     versions[self.class.to_s]
                   when Array
                     versions
      end

      normalize_pregenerated_thumbnail_variants(collection).uniq
    end

    def normalize_pregenerated_thumbnail_variants(collection)
      Array(collection).flat_map do |variant|
        if variant.is_a?(Array)
          if pregenerated_thumbnail_quality_variant?(variant)
            [[variant.first, variant.second]]
          else
            normalize_pregenerated_thumbnail_variants(variant)
          end
        elsif variant.present?
          [variant]
        else
          []
        end
      end
    end

    def pregenerated_thumbnail_quality_variant?(variant)
      variant.size == 2 && variant.first.is_a?(String) && variant.second.is_a?(Numeric)
    end

    def pregenerated_thumbnail_version(variant)
      variant.is_a?(Array) ? variant.first : variant
    end

    def pregenerated_thumbnail_quality(variant)
      variant.is_a?(Array) ? variant.second : nil
    end
end
