# frozen_string_literal: true

class AddUniqueIndexToFileSlug < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  OLD_INDEX_NAME = "index_folio_files_on_slug"
  NEW_INDEX_NAME = "index_folio_files_on_slug_unique"

  def up
    transaction { backfill_null_slugs }
    transaction { deduplicate_slugs }

    remove_index :folio_files, name: OLD_INDEX_NAME, algorithm: :concurrently

    try_add_unique_index_with_retry
  end

  def down
    remove_index :folio_files, name: NEW_INDEX_NAME, algorithm: :concurrently
    add_index :folio_files, :slug, name: OLD_INDEX_NAME, algorithm: :concurrently
  end

  private
    def try_add_unique_index_with_retry
      add_index :folio_files, :slug, unique: true, name: NEW_INDEX_NAME, algorithm: :concurrently
    rescue ActiveRecord::StatementInvalid => e
      cause = e.respond_to?(:cause) ? e.cause : nil
      is_unique_error = (cause && cause.class.name.end_with?("UniqueViolation")) || e.message.to_s =~ /duplicate key|not unique/i
      raise unless is_unique_error

      say "Unique index creation failed due to duplicates. Re-deduplicating and retrying once..."
      transaction { deduplicate_slugs }
      add_index :folio_files, :slug, unique: true, name: NEW_INDEX_NAME, algorithm: :concurrently
    end

    def backfill_null_slugs
      files = Folio::File.where(slug: [nil, ""])
      return if files.empty?

      say "Backfilling #{files.count} null/blank slug(s)..."

      files.find_each do |file|
        file.slug = generate_neutral_unique_slug
        file.save(validate: false)
      end
    end

    def deduplicate_slugs
      duplicate_slugs = Folio::File.group(:slug)
                                   .having("COUNT(*) > 1")
                                   .pluck(:slug)

      return if duplicate_slugs.empty?

      say "Found #{duplicate_slugs.size} duplicate slug group(s), deduplicating..."

      duplicate_slugs.each do |slug|
        files = Folio::File.where(slug:).order(created_at: :asc, id: :asc)

        files[1..].each_with_index do |file, idx|
          new_slug = generate_unique_slug(slug, idx + 2)
          old_slug = file.slug
          file.slug = new_slug
          file.save(validate: false)
          say " Fixed Folio::File##{file.id}: #{old_slug} → #{new_slug}"
        end
      end
    end

    def generate_unique_slug(base, suffix)
      safe_base = base.to_s[0, 230]
      candidate = "#{safe_base}-#{suffix}"

      while Folio::File.exists?(slug: candidate)
        candidate = generate_neutral_unique_slug
      end

      candidate
    end

    def generate_neutral_unique_slug
      100.times do
        candidate = "#{Time.current.to_i}-#{SecureRandom.hex(5)}"
        return candidate unless Folio::File.exists?(slug: candidate)
      end
      raise "Could not generate a unique slug after 100 attempts"
    end
end
