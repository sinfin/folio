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
      # Retry only for uniqueness-related errors
      cause = e.respond_to?(:cause) ? e.cause : nil
      is_unique_error = (cause && cause.class.name.end_with?("UniqueViolation")) || e.message.to_s =~ /duplicate key|not unique/i
      raise unless is_unique_error

      say "Unique index creation failed due to duplicates. Re-deduplicating and retrying once..."
      deduplicate_slugs
      add_index :folio_files, :slug, unique: true, name: NEW_INDEX_NAME, algorithm: :concurrently
    end

    def backfill_null_slugs
      ids = execute(<<~SQL).map { |row| row["id"].to_i }
        SELECT id FROM folio_files WHERE slug IS NULL OR slug = ''
      SQL
      return if ids.empty?

      say "Backfilling #{ids.size} null/blank slug(s)..."

      ids.each do |file_id|
        new_slug = generate_neutral_unique_slug
        execute(<<~SQL)
          UPDATE folio_files SET slug = #{connection.quote(new_slug)} WHERE id = #{file_id}
        SQL
      end
    end

    def deduplicate_slugs
      duplicate_slugs = execute(<<~SQL).map { |row| row["slug"] }
        SELECT slug FROM folio_files
        GROUP BY slug
        HAVING COUNT(*) > 1
      SQL

      return if duplicate_slugs.empty?

      say "Found #{duplicate_slugs.size} duplicate slug group(s), deduplicating..."

      duplicate_slugs.each do |slug|
        # Keep the oldest record, rename the rest in ascending order
        ids_to_fix = execute(<<~SQL).map { |row| row["id"].to_i }
          SELECT id FROM folio_files
          WHERE slug = #{connection.quote(slug)}
          ORDER BY created_at ASC, id ASC
          OFFSET 1
        SQL

        ids_to_fix.each_with_index do |file_id, idx|
          new_slug = generate_unique_slug(slug, idx + 2)
          execute(<<~SQL)
            UPDATE folio_files SET slug = #{connection.quote(new_slug)} WHERE id = #{file_id}
          SQL
          say " Fixed folio_files##{file_id}: #{slug} → #{new_slug}"
        end
      end
    end

    def generate_unique_slug(base, suffix)
      safe_base = base.to_s[0, 230]
      candidate = "#{safe_base}-#{suffix}"

      while slug_taken?(candidate)
        candidate = generate_neutral_unique_slug
      end

      candidate
    end

    def generate_neutral_unique_slug
      candidate = "#{Time.current.to_i}-#{SecureRandom.hex(5)}"
      candidate = candidate[0, 255]

      while slug_taken?(candidate)
        candidate = "#{Time.current.to_i}-#{SecureRandom.hex(6)}"
        candidate = candidate[0, 255]
      end

      candidate
    end

    def slug_taken?(slug)
      execute(<<~SQL).first["count"].to_i > 0
        SELECT COUNT(*) AS count FROM folio_files WHERE slug = #{connection.quote(slug)}
      SQL
    end
end
