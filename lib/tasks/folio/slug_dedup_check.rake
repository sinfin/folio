# frozen_string_literal: true

namespace :folio do
  namespace :file do
    desc "Dry-run of the slug deduplication that will happen in AddUniqueIndexToFileSlug migration. " \
         "Shows which files will be renamed and whether they have friendly_id history entries."
    task slug_dedup_check: :environment do
      conn = ActiveRecord::Base.connection

      duplicate_groups = conn.execute(<<~SQL).to_a
        SELECT slug, COUNT(*) AS count, array_agg(id ORDER BY created_at ASC, id ASC) AS ids
        FROM folio_files
        WHERE slug IS NOT NULL AND slug != ''
        GROUP BY slug
        HAVING COUNT(*) > 1
        ORDER BY slug
      SQL

      null_count = conn.execute(<<~SQL).first["count"].to_i
        SELECT COUNT(*) AS count FROM folio_files WHERE slug IS NULL OR slug = ''
      SQL

      puts "\n=== Folio::File slug deduplication dry-run ==="
      puts

      if null_count > 0
        puts "NULL/blank slugs (will be backfilled with neutral slug): #{null_count}"
        puts
      end

      if duplicate_groups.empty?
        puts "No duplicate slugs found. Migration is safe to run."
        next
      end

      puts "Found #{duplicate_groups.size} duplicate slug group(s):\n\n"

      total_renamed = 0

      duplicate_groups.each do |row|
        slug  = row["slug"]
        ids   = row["ids"].gsub(/[{}]/, "").split(",").map(&:to_i)
        keeper_id = ids.first
        rename_ids = ids[1..]

        files = Folio::File.where(id: ids).index_by(&:id)
        keeper = files[keeper_id]

        puts "  Slug: \"#{slug}\" (#{ids.size} files)"
        puts "  KEEP  ##{keeper_id} #{keeper&.type} — created #{keeper&.created_at&.to_date}"

        rename_ids.each_with_index do |file_id, idx|
          file = files[file_id]
          proposed_slug = "#{slug}-#{idx + 2}"

          history_entries = conn.execute(<<~SQL).to_a
            SELECT slug FROM friendly_id_slugs
            WHERE sluggable_type IN ('Folio::File', #{conn.quote(file&.type)})
              AND sluggable_id = #{file_id}
            ORDER BY created_at DESC
          SQL

          history_note = history_entries.any? ? "(has #{history_entries.size} friendly_id history entries)" : "(no friendly_id history)"

          puts "  RENAME ##{file_id} #{file&.type} — created #{file&.created_at&.to_date} → \"#{proposed_slug}\" #{history_note}"
          total_renamed += 1
        end

        puts
      end

      puts "Summary: #{total_renamed} file(s) will have their slug changed."
      puts
      puts "Note: content references (atoms, placements) use file_id and will NOT break."
      puts "      Direct URL lookups for renamed files will resolve to the keeper file instead."
      puts "      Check the list above and update any hardcoded slug references before migrating."
    end
  end
end