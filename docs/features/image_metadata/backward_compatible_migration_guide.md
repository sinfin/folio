# Backward Compatible IPTC Migration Guide

## Overview

This guide covers safely migrating existing Folio applications from legacy metadata fields (`author`, `alt`) to full IPTC-compliant metadata while maintaining **100% backward compatibility**.

## ⚠️ Critical Safety Features

- **Zero Downtime**: Migration can be run on production without affecting users
- **Data Preservation**: All legacy data is preserved in `*_legacy` columns as backup
- **No Breaking Changes**: Existing application code continues working unchanged
- **Rollback Safe**: Full rollback capability if needed
- **Batch Processing**: Memory-efficient processing for large datasets

## Migration Process

### 1. Database Schema Migration

Run the database migration to add new IPTC fields and rename legacy fields:

```bash
rails db:migrate
```

This migration:
- ✅ Renames `author` → `author_legacy` (backup)
- ✅ Renames `alt` → `alt_legacy` (backup) 
- ✅ Adds all IPTC-compliant fields (`creator`, `headline`, `keywords`, etc.)
- ✅ Re-adds `author` and `alt` as new fields (for BC)
- ✅ Creates proper indexes for performance

### 2. Check Migration Status

Before migrating data, check the current state:

```bash
rails folio:developer_tools:metadata_migration_status
```

Example output:
```
🏗️  SCHEMA STATUS:
   Legacy author column: ✅
   Legacy alt column: ✅
   New IPTC fields: ✅

📊 DATA STATUS:
   Total files: 15,847
   Files with IPTC data: 0
   Files needing migration: 15,847
   Status: ⚠️  Migration needed
```

### 3. Data Migration

Migrate legacy data to new IPTC fields:

```bash
rails folio:developer_tools:migrate_legacy_metadata
```

This task:
- ✅ Copies `author_legacy` → `author` (string) + `creator` (JSONB array)
- ✅ Copies `alt_legacy` → `alt` + `headline`
- ✅ Processes files in batches (memory efficient)
- ✅ Shows progress and statistics
- ✅ **NO metadata extraction is triggered**
- ✅ Preserves all legacy columns as backup

Example output:
```
📊 PRE-MIGRATION ANALYSIS:
   Legacy author column: ✅ Found
   Legacy alt column: ✅ Found
   New IPTC fields: ✅ Found

📈 MIGRATION STATS:
   Total files: 15,847
   Files needing migration: 15,847
   Files already migrated: 0

🚀 Starting migration...
   Migrated 500 files...
   Migrated 1000 files...
   ...

✅ MIGRATION COMPLETED!
   Successfully migrated: 15,847 files
   Errors encountered: 0 files
```

### 4. Verify Migration

Check that migration completed successfully:

```bash
rails folio:developer_tools:metadata_migration_status
```

Expected result:
```
📊 DATA STATUS:
   Total files: 15,847
   Files with IPTC data: 15,847
   Files needing migration: 0
   Status: ✅ Fully migrated
```

## Backward Compatibility

### Method Compatibility

All existing method calls continue working without changes:

```ruby
# OLD CODE - continues working unchanged
image = Folio::File::Image.find(123)

# Reading
image.author          # Returns string (backward compatible)
image.alt             # Returns string (backward compatible)
image.tag_list        # Returns comma-separated keywords
image.author_name     # Still works

# Writing  
image.author = "John Doe"     # Works, updates both author + creator
image.alt = "My Title"        # Works, updates both alt + headline
image.tag_list = "a,b,c"      # Works, updates keywords array
```

### New IPTC Methods

Access to full IPTC metadata is also available:

```ruby
# NEW IPTC-COMPLIANT ACCESS
image.creator         # Returns ["John Doe"] (JSONB array)
image.headline        # Returns "My Title" 
image.keywords        # Returns ["a", "b", "c"] (JSONB array)
image.copyright_notice # IPTC copyright field
image.gps_latitude    # GPS coordinates
```

### Field Precedence

Backward compatible fields use intelligent precedence:

```ruby
# author field precedence:
# 1. New author field (string)
# 2. First creator from array  
# 3. Legacy backup (author_legacy)

# alt field precedence:
# 1. New alt field
# 2. headline field
# 3. Legacy backup (alt_legacy)
```

## Testing Backward Compatibility

### Manual Testing

```ruby
rails console

# Test existing file
file = Folio::File::Image.first

# Test backward compatibility
file.author = "Test Author"
file.alt = "Test Alt"
file.save!

# Verify both old and new fields work
puts file.author        # "Test Author"
puts file.creator       # ["Test Author"] 
puts file.alt           # "Test Alt"
puts file.headline      # "Test Alt"
```

### Application Testing

1. **Run existing test suite** - should pass without changes
2. **Test file upload forms** - should work normally  
3. **Test admin interfaces** - should display fields correctly
4. **Test API responses** - should include both old and new fields

## Rollback Procedure

If issues arise, you can safely rollback:

### 1. Rollback Database Migration

```bash
rails db:rollback STEP=1
```

This will:
- ✅ Restore original `author` and `alt` columns
- ✅ Remove all IPTC fields
- ✅ Restore original schema exactly

### 2. Verify Rollback

```bash
# Check that data is intact
rails console
Folio::File::Image.first.author  # Should show original data
```

## Post-Migration Tasks

### 1. Enable IPTC Metadata Extraction

After successful migration, you can enable automatic metadata extraction for new uploads:

```ruby
# config/initializers/folio.rb
Rails.application.config.folio_image_metadata_extraction_enabled = true
```

### 2. Extract Metadata for Existing Files

Optionally extract IPTC metadata from existing image files:

```bash
# Extract metadata for files that don't have it yet
rails folio:images:extract_metadata
```

### 3. Clean Up Legacy Columns (Optional)

**⚠️ DANGER**: Only after thorough testing and with backups!

```bash
# This permanently deletes backup columns
rails folio:developer_tools:cleanup_legacy_metadata_columns
```

## Production Deployment

### Recommended Deployment Steps

1. **Test on staging** with production data copy
2. **Schedule maintenance window** (optional, zero-downtime)
3. **Deploy code** with migration
4. **Run data migration** during low-traffic period
5. **Monitor application logs** for compatibility issues
6. **Verify all functionality** works as expected

### Zero-Downtime Deployment

The migration is designed for zero-downtime deployment:

1. Deploy new code (backward compatible)
2. Run database migration (adds fields, renames existing)
3. Run data migration (copies data to new fields)
4. Application works throughout the process

### Monitoring

Monitor these metrics post-deployment:

- Application error rates
- Database query performance  
- File upload functionality
- Admin interface responsiveness

## Troubleshooting

### Common Issues

**Files not showing metadata**
- Check migration status: `rails folio:developer_tools:metadata_migration_status`
- Run data migration if needed

**Application errors after migration**
- Check that `Folio::BackwardCompatibleIptcMetadata` is included
- Verify field aliases are working correctly

**Performance issues**
- Check that GIN indexes were created
- Monitor JSONB field query performance

### Support

If you encounter issues:

1. Check migration status with provided tools
2. Review application logs for specific errors
3. Test with small dataset first
4. Keep legacy columns as backup until confident

## Advanced Configuration

### Custom Field Mapping

You can customize how legacy fields map to IPTC fields:

```ruby
# config/initializers/folio.rb
Rails.application.config.folio_image_metadata_custom_mappings = {
  headline: ["XMP-custom:Title", "XMP-photoshop:Headline", "Headline"],
  source: ["XMP-custom:Agency", "XMP-iptcCore:Source"]  
}
```

### Selective Migration

Skip specific fields during migration:

```ruby
# config/initializers/folio.rb  
Rails.application.config.folio_image_metadata_skip_fields = [:urgency, :category]
```

---

*This migration guide ensures your Folio application can safely adopt IPTC metadata standards while maintaining full backward compatibility with existing code and data.*
