# frozen_string_literal: true

class BackfillKeywordsForSearchFromMappedMetadata < ActiveRecord::Migration[8.0]
  def up
    # This migration fixes the keywords_for_search column for existing files
    # The original migration looked for file_metadata->'keywords', but keywords
    # are actually stored in IPTC/XMP namespaced fields like 'XMP-dc:Subject',
    # 'IPTC:Keywords', etc.
    #
    # We need to use the IptcFieldMapper to properly extract keywords.

    say_with_time "Backfilling keywords_for_search from IPTC/XMP metadata" do
      # Process in batches to avoid memory issues
      batch_size = 500
      updated_count = 0

      # Find all files that have metadata but no keywords_for_search yet
      Folio::File.where.not(file_metadata: nil)
                 .where(keywords_for_search: nil)
                 .in_batches(of: batch_size) do |batch|
        batch.each do |file|
          # Try to get keywords from mapped_metadata (IPTC/XMP fields)
          keywords = if file.respond_to?(:mapped_metadata)
            file.mapped_metadata[:keywords]
          else
            # Fallback for non-Image files or simplified metadata
            file.file_metadata&.dig("keywords")
          end

          # If mapped_metadata didn't find anything, try plain 'keywords' key
          keywords ||= file.file_metadata&.dig("keywords")

          next if keywords.blank?

          keywords_string = case keywords
          when Array then keywords.join(" ")
          when String then keywords
          else nil
          end

          if keywords_string.present?
            file.update_column(:keywords_for_search, keywords_string)
            updated_count += 1
          end
        end
      end

      say "Updated #{updated_count} files with keywords", true
    end
  end

  def down
    # No need to reverse - this is a data migration
    say "This is a data migration - no reversal needed"
  end
end
