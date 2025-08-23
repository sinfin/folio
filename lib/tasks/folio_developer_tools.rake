# frozen_string_literal: true

namespace :folio do
  namespace :developer_tools do
    desc "Safely migrate legacy metadata fields to new IPTC-compliant fields"
    task migrate_legacy_metadata: :environment do
      puts ""
      puts "=" * 80
      puts "FOLIO LEGACY METADATA MIGRATION"
      puts "=" * 80
      puts ""
      
      # Check if we have the necessary columns
      has_legacy_author = ActiveRecord::Base.connection.column_exists?(:folio_files, :author_legacy)
      has_legacy_alt = ActiveRecord::Base.connection.column_exists?(:folio_files, :alt_legacy)
      has_new_fields = ActiveRecord::Base.connection.column_exists?(:folio_files, :creator) && 
                      ActiveRecord::Base.connection.column_exists?(:folio_files, :headline)
      
      unless has_new_fields
        puts "❌ ERROR: New IPTC fields not found!"
        puts "   Please run: rails db:migrate first"
        exit 1
      end
      
      puts "📊 PRE-MIGRATION ANALYSIS:"
      puts "   Legacy author column: #{has_legacy_author ? '✅ Found' : '❌ Not found'}"
      puts "   Legacy alt column: #{has_legacy_alt ? '✅ Found' : '❌ Not found'}"
      puts "   New IPTC fields: ✅ Found"
      puts ""
      
      # Count total files and files needing migration
      total_files = Folio::File.count
      files_needing_migration = Folio::File.legacy_migration_count
      
      puts "📈 MIGRATION STATS:"
      puts "   Total files: #{total_files}"
      puts "   Files needing migration: #{files_needing_migration}"
      puts "   Files already migrated: #{total_files - files_needing_migration}"
      puts ""
      
      if files_needing_migration == 0
        puts "✅ No files need migration. All data is already in IPTC format!"
        puts "=" * 80
        exit 0
      end
      
      puts "🔄 MIGRATION PLAN:"
      puts "   1. Copy author_legacy → author (string) + creator (JSONB array)"
      puts "   2. Copy alt_legacy → alt + headline"
      puts "   3. Preserve all legacy columns as backup"
      puts "   4. NO metadata extraction will be triggered"
      puts "   5. Update in batches to avoid memory issues"
      puts ""
      
      # Confirmation prompt
      print "Do you want to proceed? [y/N]: "
      unless STDIN.gets.chomp.downcase.in?(['y', 'yes'])
        puts "Migration cancelled."
        exit 0
      end
      
      puts ""
      puts "🚀 Starting migration..."
      puts ""
      
      migrated_count = 0
      error_count = 0
      batch_size = 500
      
      # Use find_each for memory efficiency with large datasets
      Folio::File.needing_legacy_migration.find_each(batch_size: batch_size) do |file|
        begin
          updates = {}
          
          # Migrate author_legacy → author + creator
          if has_legacy_author && file[:author_legacy].present? && file.creator.blank?
            author_value = file[:author_legacy].to_s.strip
            updates[:author] = author_value
            updates[:creator] = [author_value]
          end
          
          # Migrate alt_legacy → alt + headline  
          if has_legacy_alt && file[:alt_legacy].present? && file.headline.blank?
            alt_value = file[:alt_legacy].to_s.strip
            updates[:alt] = alt_value
            updates[:headline] = alt_value
          end
          
          # Only update if we have changes
          if updates.any?
            file.update_columns(updates)
            migrated_count += 1
            
            # Progress indicator
            if migrated_count % 100 == 0
              puts "   Migrated #{migrated_count} files..."
            end
          end
          
        rescue => e
          error_count += 1
          puts "   ❌ Error migrating file ##{file.id}: #{e.message}"
          
          # Continue with other files, don't fail entire migration
          next
        end
      end
      
      puts ""
      puts "✅ MIGRATION COMPLETED!"
      puts ""
      puts "📊 FINAL STATS:"
      puts "   Successfully migrated: #{migrated_count} files"
      puts "   Errors encountered: #{error_count} files"
      puts "   Legacy columns preserved: ✅"
      puts ""
      
      # Verify migration results
      remaining_files = Folio::File.legacy_migration_count
      puts "🔍 VERIFICATION:"
      puts "   Files still needing migration: #{remaining_files}"
      
      if remaining_files > 0
        puts "   ⚠️  Some files may need manual review"
      else
        puts "   ✅ All applicable files successfully migrated!"
      end
      
      puts ""
      puts "💡 NEXT STEPS:"
      puts "   1. Test your application to ensure compatibility"
      puts "   2. Legacy columns (*_legacy) are preserved as backup"
      puts "   3. Use rails folio:images:extract_metadata for new IPTC extraction"
      puts "   4. Monitor application logs for any compatibility issues"
      puts ""
      puts "=" * 80
    end
    
    desc "Show metadata migration status and statistics"
    task metadata_migration_status: :environment do
      puts ""
      puts "=" * 60
      puts "FOLIO METADATA MIGRATION STATUS"
      puts "=" * 60
      puts ""
      
      # Check column existence
      has_legacy_author = ActiveRecord::Base.connection.column_exists?(:folio_files, :author_legacy)
      has_legacy_alt = ActiveRecord::Base.connection.column_exists?(:folio_files, :alt_legacy)
      has_new_fields = ActiveRecord::Base.connection.column_exists?(:folio_files, :creator) && 
                      ActiveRecord::Base.connection.column_exists?(:folio_files, :headline)
      
      puts "🏗️  SCHEMA STATUS:"
      puts "   Legacy author column: #{has_legacy_author ? '✅' : '❌'}"
      puts "   Legacy alt column: #{has_legacy_alt ? '✅' : '❌'}"  
      puts "   New IPTC fields: #{has_new_fields ? '✅' : '❌'}"
      puts ""
      
      if has_new_fields
        total_files = Folio::File.count
        files_needing_migration = Folio::File.legacy_migration_count
        
        puts "📊 DATA STATUS:"
        puts "   Total files: #{total_files}"
        puts "   Files with IPTC data: #{total_files - files_needing_migration}"
        puts "   Files needing migration: #{files_needing_migration}"
        
        if files_needing_migration > 0
          puts "   Status: ⚠️  Migration needed"
          puts ""
          puts "   Run: rails folio:developer_tools:migrate_legacy_metadata"
        else
          puts "   Status: ✅ Fully migrated"
        end
        
        puts ""
        puts "🎯 METADATA COVERAGE:"
        
        # Show coverage statistics
        coverage_stats = {
          "Headlines" => Folio::File.where.not(headline: [nil, ""]).count,
          "Creators" => Folio::File.where("creator != '[]' AND creator IS NOT NULL").count,
          "Keywords" => Folio::File.where("keywords != '[]' AND keywords IS NOT NULL").count,
          "Copyright" => Folio::File.where.not(copyright_notice: [nil, ""]).count,
          "GPS Data" => Folio::File.where.not(gps_latitude: nil, gps_longitude: nil).count
        }
        
        coverage_stats.each do |field, count|
          percentage = total_files > 0 ? (count.to_f / total_files * 100).round(1) : 0
          puts "   #{field}: #{count}/#{total_files} (#{percentage}%)"
        end
      else
        puts "❌ New IPTC fields not found. Please run: rails db:migrate"
      end
      
      puts ""
      puts "=" * 60
    end
    
    desc "Clean up legacy metadata columns after successful migration (DANGEROUS)"
    task cleanup_legacy_metadata_columns: :environment do
      puts ""
      puts "⚠️  WARNING: DESTRUCTIVE OPERATION!"
      puts "=" * 50
      puts ""
      puts "This task will permanently delete backup columns:"
      puts "  - author_legacy"
      puts "  - alt_legacy"
      puts ""
      puts "Make sure you have:"
      puts "  1. ✅ Successfully migrated all data"
      puts "  2. ✅ Tested your application thoroughly"  
      puts "  3. ✅ Database backups available"
      puts ""
      
      # Double confirmation for dangerous operation
      print "Type 'DELETE LEGACY COLUMNS' to confirm: "
      confirmation = STDIN.gets.chomp
      
      unless confirmation == "DELETE LEGACY COLUMNS"
        puts "Operation cancelled. Legacy columns preserved."
        exit 0
      end
      
      puts ""
      puts "🗑️  Removing legacy columns..."
      
      if ActiveRecord::Base.connection.column_exists?(:folio_files, :author_legacy)
        ActiveRecord::Migration[7.1].remove_column :folio_files, :author_legacy
        puts "   ✅ Removed author_legacy column"
      end
      
      if ActiveRecord::Base.connection.column_exists?(:folio_files, :alt_legacy)
        ActiveRecord::Migration[7.1].remove_column :folio_files, :alt_legacy  
        puts "   ✅ Removed alt_legacy column"
      end
      
      puts ""
      puts "✅ Legacy columns cleanup completed!"
      puts "   Your database is now fully IPTC-compliant with no legacy columns."
      puts ""
    end
  end
end
