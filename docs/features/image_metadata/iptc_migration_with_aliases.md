# IPTC Migration with Backward Compatibility Aliases

## Migration Strategy

Rename existing fields to IPTC-compliant names while maintaining backward compatibility through read/write aliases.

## Database Migration

```ruby
# db/migrate/add_iptc_compliance_to_folio_files.rb
class AddIptcComplianceToFolioFiles < ActiveRecord::Migration[7.0]
  def change
    # 1. Rename existing fields to IPTC standard names
    rename_column :folio_files, :author, :creator_old if column_exists?(:folio_files, :author)
    rename_column :folio_files, :description, :description_old if column_exists?(:folio_files, :description)
    rename_column :folio_files, :alt, :headline if column_exists?(:folio_files, :alt)
    
    # 2. Add new IPTC-compliant fields
    
    # Core descriptive fields
    add_column :folio_files, :creator, :jsonb, default: [] unless column_exists?(:folio_files, :creator)
    add_column :folio_files, :caption_writer, :string unless column_exists?(:folio_files, :caption_writer)
    add_column :folio_files, :credit_line, :string unless column_exists?(:folio_files, :credit_line)
    
    # Rename description_old back to description (keeping it as text field)
    rename_column :folio_files, :description_old, :description if column_exists?(:folio_files, :description_old)
    
    # Rights management
    add_column :folio_files, :copyright_notice, :text unless column_exists?(:folio_files, :copyright_notice)
    add_column :folio_files, :copyright_marked, :boolean, default: false unless column_exists?(:folio_files, :copyright_marked)
    add_column :folio_files, :usage_terms, :text unless column_exists?(:folio_files, :usage_terms)
    add_column :folio_files, :rights_usage_info, :string unless column_exists?(:folio_files, :rights_usage_info)
    
    # Classification (JSONB arrays)
    add_column :folio_files, :keywords, :jsonb, default: [] unless column_exists?(:folio_files, :keywords)
    add_column :folio_files, :intellectual_genre, :string unless column_exists?(:folio_files, :intellectual_genre)
    add_column :folio_files, :subject_codes, :jsonb, default: [] unless column_exists?(:folio_files, :subject_codes)
    add_column :folio_files, :scene_codes, :jsonb, default: [] unless column_exists?(:folio_files, :scene_codes)
    add_column :folio_files, :event, :string unless column_exists?(:folio_files, :event)
    
    # Legacy fields (for backwards compatibility)
    add_column :folio_files, :category, :string unless column_exists?(:folio_files, :category)
    add_column :folio_files, :urgency, :integer unless column_exists?(:folio_files, :urgency)
    
    # People and objects (JSONB arrays)
    add_column :folio_files, :persons_shown, :jsonb, default: [] unless column_exists?(:folio_files, :persons_shown)
    add_column :folio_files, :persons_shown_details, :jsonb, default: [] unless column_exists?(:folio_files, :persons_shown_details)
    add_column :folio_files, :organizations_shown, :jsonb, default: [] unless column_exists?(:folio_files, :organizations_shown)
    
    # Location data
    add_column :folio_files, :location_created, :jsonb, default: [] unless column_exists?(:folio_files, :location_created)
    add_column :folio_files, :location_shown, :jsonb, default: [] unless column_exists?(:folio_files, :location_shown)
    add_column :folio_files, :sublocation, :string unless column_exists?(:folio_files, :sublocation)
    add_column :folio_files, :city, :string unless column_exists?(:folio_files, :city)
    add_column :folio_files, :state_province, :string unless column_exists?(:folio_files, :state_province)
    add_column :folio_files, :country, :string unless column_exists?(:folio_files, :country)
    add_column :folio_files, :country_code, :string, limit: 2 unless column_exists?(:folio_files, :country_code)
    
    # Technical metadata
    add_column :folio_files, :camera_make, :string unless column_exists?(:folio_files, :camera_make)
    add_column :folio_files, :camera_model, :string unless column_exists?(:folio_files, :camera_model)
    add_column :folio_files, :lens_info, :string unless column_exists?(:folio_files, :lens_info)
    add_column :folio_files, :capture_date, :datetime unless column_exists?(:folio_files, :capture_date)
    add_column :folio_files, :capture_date_offset, :string unless column_exists?(:folio_files, :capture_date_offset)
    
    # Keep existing GPS columns if they exist, add if missing
    add_column :folio_files, :gps_latitude, :decimal, precision: 10, scale: 6 unless column_exists?(:folio_files, :gps_latitude)
    add_column :folio_files, :gps_longitude, :decimal, precision: 10, scale: 6 unless column_exists?(:folio_files, :gps_longitude)
    add_column :folio_files, :orientation, :integer unless column_exists?(:folio_files, :orientation)
    
    # Metadata extraction tracking
    add_column :folio_files, :file_metadata_extracted_at, :datetime unless column_exists?(:folio_files, :file_metadata_extracted_at)
    
    # Indexes for common searches (GIN for JSONB arrays)
    add_index :folio_files, :creator, using: :gin unless index_exists?(:folio_files, :creator)
    add_index :folio_files, :keywords, using: :gin unless index_exists?(:folio_files, :keywords)
    add_index :folio_files, :subject_codes, using: :gin unless index_exists?(:folio_files, :subject_codes)
    add_index :folio_files, :persons_shown, using: :gin unless index_exists?(:folio_files, :persons_shown)
    add_index :folio_files, :source unless index_exists?(:folio_files, :source)
    add_index :folio_files, :country_code unless index_exists?(:folio_files, :country_code)
    add_index :folio_files, :capture_date unless index_exists?(:folio_files, :capture_date)
    add_index :folio_files, [:gps_latitude, :gps_longitude] unless index_exists?(:folio_files, [:gps_latitude, :gps_longitude])
    
    # Migrate data from old creator column to new JSONB array
    if column_exists?(:folio_files, :creator_old)
      execute <<-SQL
        UPDATE folio_files 
        SET creator = CASE 
          WHEN creator_old IS NOT NULL AND creator_old != '' 
          THEN jsonb_build_array(creator_old)
          ELSE '[]'::jsonb
        END
        WHERE creator_old IS NOT NULL
      SQL
      
      # Remove old column after migration
      remove_column :folio_files, :creator_old
    end
  end
  
  def down
    # Reverse migration if needed
    # Note: Some data transformations may not be perfectly reversible (JSONB -> string)
    
    # Convert creator JSONB array back to string
    if column_exists?(:folio_files, :creator)
      add_column :folio_files, :author, :string unless column_exists?(:folio_files, :author)
      execute <<-SQL
        UPDATE folio_files 
        SET author = creator->0
        WHERE jsonb_array_length(creator) > 0
      SQL
      remove_column :folio_files, :creator
    end
    
    rename_column :folio_files, :headline, :alt if column_exists?(:folio_files, :headline)
    
    # Remove IPTC-specific columns
    remove_column :folio_files, :caption_writer if column_exists?(:folio_files, :caption_writer)
    remove_column :folio_files, :credit_line if column_exists?(:folio_files, :credit_line)
    remove_column :folio_files, :copyright_notice if column_exists?(:folio_files, :copyright_notice)
    remove_column :folio_files, :copyright_marked if column_exists?(:folio_files, :copyright_marked)
    # ... remove other IPTC columns
  end
end
```

## Model with Backward Compatibility Aliases

```ruby
# app/models/concerns/folio/iptc_metadata_aliases.rb
module Folio::IptcMetadataAliases
  extend ActiveSupport::Concern
  
  included do
    # Backward compatibility aliases for renamed fields
    
    # author -> creator (string to JSONB array)
    def author
      creator&.first
    end
    
    def author=(value)
      self.creator = value.present? ? [value] : []
    end
    
    # alt -> headline
    alias_attribute :alt, :headline
    
    # attribution_source -> source
    alias_attribute :attribution_source, :source
    
    # attribution_copyright -> copyright_notice
    alias_attribute :attribution_copyright, :copyright_notice
    
    # Support both array and string access for keywords
    def keywords_string
      keywords&.join(", ")
    end
    
    def keywords_string=(value)
      self.keywords = value.to_s.split(/,\s*/).reject(&:blank?)
    end
    
    # Ensure creator is always an array
    def creator=(value)
      super(
        case value
        when Array then value.compact.reject(&:blank?)
        when String then [value].compact.reject(&:blank?)
        else []
        end
      )
    end
    
    # Handle legacy access patterns
    def author_name
      author # Uses the alias above
    end
    
    def authors
      creator # Returns the full array
    end
  end
end

# app/models/folio/file.rb
class Folio::File < ApplicationRecord
  include Folio::IptcMetadataAliases
  # ... existing includes ...
  
  # IPTC metadata extraction after upload
  after_commit :extract_iptc_metadata_async, on: :create
  
  private
  
  def extract_iptc_metadata_async
    Folio::ExtractMetadataJob.perform_later(self) if is_a?(Folio::File::Image)
  end
end

# app/models/folio/file/image.rb
class Folio::File::Image < Folio::File
  # ... existing code ...
  
  def extract_iptc_metadata!
    return unless file.present?
    return unless file_metadata.present? || extract_raw_metadata.present?
    
    raw_metadata = file_metadata || extract_raw_metadata
    mapped_fields = Folio::Metadata::IptcFieldMapper.map_metadata(raw_metadata)
    
    # Only update blank fields (preserve user edits)
    update_fields = {}
    mapped_fields.each do |field, value|
      # Check if field is blank (handles both nil and empty arrays/strings)
      current_value = send(field) rescue nil
      is_blank = current_value.blank? || (current_value.is_a?(Array) && current_value.empty?)
      
      if is_blank && value.present?
        update_fields[field] = value
      end
    end
    
    if update_fields.any?
      update_fields[:file_metadata_extracted_at] = Time.current
      update!(update_fields)
    end
  end
  
  private
  
  def extract_raw_metadata
    return {} unless file&.path.present?
    
    stdout, stderr, status = Open3.capture3(
      "exiftool", "-j", "-G1", "-struct", "-n", file.path
    )
    
    if status.success?
      metadata = JSON.parse(stdout).first || {}
      update_column(:file_metadata, metadata) # Cache for future use
      metadata
    else
      Rails.logger.error "ExifTool error: #{stderr}"
      {}
    end
  end
end
```

## Job for Async Processing

```ruby
# app/jobs/folio/extract_metadata_job.rb
class Folio::ExtractMetadataJob < ApplicationJob
  queue_as :low
  
  def perform(image)
    return unless image.is_a?(Folio::File::Image)
    
    # Skip if metadata already extracted (unless forced)
    return if image.file_metadata_extracted_at.present?
    
    image.extract_iptc_metadata!
  rescue => e
    Rails.logger.error "Metadata extraction failed for file ##{image.id}: #{e.message}"
    # Don't retry - metadata extraction is not critical
  end
end
```

## Configuration

```ruby
# config/initializers/folio_metadata.rb
Rails.application.config.tap do |config|
  # Enable automatic metadata extraction on upload
  config.folio_image_metadata_extraction_enabled = true
  
  # Only extract if these tools are available
  config.folio_image_metadata_require_exiftool = true
  
  # Language priority for Lang Alt fields (dc:description, dc:rights, etc.)
  # For Czech applications:
  config.folio_image_metadata_locale_priority = [:cs, :en, "x-default"]
  # Default: [:en, "x-default"]
  
  # Fields that should never be overwritten by extraction
  config.folio_image_metadata_protected_fields = [
    :headline, :description, :creator, :copyright_notice
  ]
  
  # Fields required for agency compliance (optional validation)
  config.folio_image_metadata_required_fields = []  # Empty by default
end
```

## Usage Examples

### Legacy Code Compatibility

```ruby
# Old code continues to work unchanged
image = Folio::File::Image.find(123)

# Reading
image.author          # Returns first creator (string)
image.alt            # Returns headline (aliased)
image.attribution_source  # Returns source (aliased)

# Writing
image.author = "John Doe"  # Sets creator to ["John Doe"]
image.alt = "My Title"     # Sets headline
image.save

# New IPTC-compliant access
image.creator         # Returns ["John Doe"] (JSONB array)
image.headline        # Returns "My Title"
image.keywords        # Returns ["nature", "landscape"] (JSONB array)
```

### Manual Metadata Extraction

```ruby
# Re-extract metadata (admin action)
image = Folio::File::Image.find(456)

# Normal extraction (preserves existing data)
image.extract_iptc_metadata!

# Force overwrite (admin only)
image.update!(
  creator: nil,
  keywords: nil,
  headline: nil
)
image.extract_iptc_metadata!
```

### Bulk Migration of Existing Files

```ruby
# lib/tasks/folio_iptc_migration.rake
namespace :folio do
  desc "Migrate existing files to IPTC metadata"
  task migrate_to_iptc: :environment do
    
    # First, extract metadata for files that don't have it
    scope = Folio::File::Image.where(file_metadata_extracted_at: nil)
    
    puts "Extracting metadata for #{scope.count} images..."
    
    scope.find_each do |image|
      image.extract_iptc_metadata!
      print "."
    rescue => e
      puts "\nError with image ##{image.id}: #{e.message}"
    end
    
    puts "\nMetadata extraction complete!"
    
    # Then migrate old author field to creator if needed
    if ActiveRecord::Base.connection.column_exists?(:folio_files, :author)
      Folio::File.where.not(author: [nil, ""]).find_each do |file|
        file.update_column(:creator, [file.author]) if file.creator.blank?
      end
      puts "Migrated author field to creator array"
    end
  end
end
```

## Testing Backward Compatibility

```ruby
# test/models/folio/file/iptc_aliases_test.rb
require 'test_helper'

class Folio::File::IptcAliasesTest < ActiveSupport::TestCase
  test "author alias works for reading and writing" do
    image = Folio::File::Image.new
    
    # Write via old field name
    image.author = "John Doe"
    assert_equal ["John Doe"], image.creator
    assert_equal "John Doe", image.author
    
    # Write via new field name
    image.creator = ["Jane Smith", "Bob Johnson"]
    assert_equal "Jane Smith", image.author  # Returns first
    assert_equal ["Jane Smith", "Bob Johnson"], image.creator
  end
  
  test "alt aliases to headline" do
    image = Folio::File::Image.new
    
    image.alt = "Test Headline"
    assert_equal "Test Headline", image.headline
    assert_equal "Test Headline", image.alt
    
    image.headline = "New Headline"
    assert_equal "New Headline", image.alt
  end
  
  test "keywords handle both array and string access" do
    image = Folio::File::Image.new
    
    # Set as string
    image.keywords_string = "nature, landscape, sunset"
    assert_equal ["nature", "landscape", "sunset"], image.keywords
    
    # Get as string
    image.keywords = ["city", "night", "lights"]
    assert_equal "city, night, lights", image.keywords_string
  end
  
  test "extraction preserves existing data" do
    image = Folio::File::Image.create!(
      site: sites(:default),
      file: fixture_file_upload('test.jpg'),
      author: "Manual Author",
      description: "Manual Description"
    )
    
    # Simulate metadata extraction
    image.extract_iptc_metadata!
    
    # Should preserve manually set values
    assert_equal "Manual Author", image.author
    assert_equal ["Manual Author"], image.creator
    assert_equal "Manual Description", image.description
  end
end
```

## Summary

This implementation provides:

1. **Full IPTC compliance** with proper field names and types
2. **Complete backward compatibility** through aliases
3. **Data preservation** - never overwrites existing user data
4. **Async processing** - metadata extraction happens in background
5. **Zero breaking changes** - existing code continues to work

The migration is safe to run multiple times and handles existing data gracefully.
