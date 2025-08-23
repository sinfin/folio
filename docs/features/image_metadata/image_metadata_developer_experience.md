# Developer Experience for Image Metadata

## Rails Generators

### 1. Custom Metadata Extractor Generator

```bash
rails generate folio:metadata_extractor PhotoAgency
```

This generates:
```ruby
# app/extractors/photo_agency_metadata_extractor.rb
class PhotoAgencyMetadataExtractor < Folio::Metadata::BaseExtractor
  # Define source fields to extract from
  source_fields :Artist, :Creator, :Copyright, :Source
  
  # Define target database columns
  maps_to :author, :description, :keywords, :attribution_source
  
  # Optional: Custom extraction logic
  def extract_author(metadata)
    # Priority order for author extraction
    metadata["Artist"] || 
    metadata["Creator"] || 
    metadata["Copyright"]&.split("©")&.last&.strip
  end
  
  def extract_keywords(metadata)
    keywords = metadata["Keywords"] || []
    keywords += metadata["Subject"] if metadata["Subject"]
    keywords.uniq.join(", ")
  end
  
  # Optional: Validation
  def validate_metadata(metadata)
    errors = []
    errors << "Missing author information" unless extract_author(metadata).present?
    errors << "No keywords found" if extract_keywords(metadata).blank?
    errors
  end
  
  # Optional: Post-processing
  def after_extraction(file)
    # Called after metadata is saved to file
    Folio::MetadataIndexJob.perform_later(file) if file.keywords_changed?
  end
end

# test/extractors/photo_agency_metadata_extractor_test.rb
require "test_helper"

class PhotoAgencyMetadataExtractorTest < ActiveSupport::TestCase
  setup do
    @extractor = PhotoAgencyMetadataExtractor.new
    @sample_metadata = {
      "Artist" => "John Doe",
      "Keywords" => ["nature", "landscape"],
      "Description" => "Beautiful sunset"
    }
  end
  
  test "extracts author from Artist field" do
    result = @extractor.extract_author(@sample_metadata)
    assert_equal "John Doe", result
  end
  
  test "validates required metadata" do
    errors = @extractor.validate_metadata({})
    assert_includes errors, "Missing author information"
  end
end
```

### 2. Metadata Field Generator

```bash
rails generate folio:metadata_field location --type=jsonb
```

Generates migration:
```ruby
# db/migrate/xxx_add_location_metadata_to_folio_files.rb
class AddLocationMetadataToFolioFiles < ActiveRecord::Migration[7.0]
  def change
    add_column :folio_files, :location_metadata, :jsonb, default: {}
    add_index :folio_files, :location_metadata, using: :gin
  end
end
```

And model concern:
```ruby
# app/models/concerns/folio/location_metadata.rb
module Folio::LocationMetadata
  extend ActiveSupport::Concern
  
  included do
    store_accessor :location_metadata,
      :country,
      :city,
      :region,
      :gps_latitude,
      :gps_longitude,
      :altitude,
      :direction
      
    scope :with_location, -> { where.not(location_metadata: {}) }
    scope :in_country, ->(country) { where("location_metadata->>'country' = ?", country) }
    
    after_commit :extract_location_metadata, on: :create
  end
  
  def has_gps_coordinates?
    gps_latitude.present? && gps_longitude.present?
  end
  
  def coordinates
    [gps_latitude, gps_longitude] if has_gps_coordinates?
  end
  
  private
  
  def extract_location_metadata
    return unless file_metadata.present?
    
    self.location_metadata = {
      country: file_metadata["Country"],
      city: file_metadata["City"],
      region: file_metadata["Province-State"],
      gps_latitude: parse_gps(file_metadata["GPSLatitude"]),
      gps_longitude: parse_gps(file_metadata["GPSLongitude"]),
      altitude: file_metadata["GPSAltitude"],
      direction: file_metadata["GPSImgDirection"]
    }
    
    save if location_metadata_changed?
  end
  
  def parse_gps(value)
    # GPS parsing logic
  end
end
```

## Hooks and Events

### 1. Metadata Extraction Hooks

```ruby
# app/models/concerns/folio/metadata_hooks.rb
module Folio::MetadataHooks
  extend ActiveSupport::Concern
  
  included do
    # Define available hooks
    define_model_callbacks :metadata_extraction,
                          :metadata_validation,
                          :metadata_mapping,
                          :metadata_save
  end
  
  # Hook: Before extraction
  # Usage: before_metadata_extraction :prepare_file
  def run_metadata_extraction
    run_callbacks :metadata_extraction do
      extract_metadata_from_file
    end
  end
  
  # Hook: After validation
  # Usage: after_metadata_validation :log_validation_errors
  def validate_metadata
    run_callbacks :metadata_validation do
      @metadata_valid = metadata_validator.valid?
    end
  end
  
  # Hook: Around mapping
  # Usage: around_metadata_mapping :benchmark_mapping
  def map_metadata
    run_callbacks :metadata_mapping do
      self.attributes = metadata_mapper.map(@raw_metadata)
    end
  end
  
  # Hook: After save
  # Usage: after_metadata_save :notify_external_service
  def save_with_metadata
    run_callbacks :metadata_save do
      save!
    end
  end
end

# Usage in application:
class ApplicationImage < Folio::File::Image
  include Folio::MetadataHooks
  
  before_metadata_extraction :check_file_size
  after_metadata_extraction :process_special_fields
  around_metadata_mapping :log_mapping_time
  after_metadata_save :update_search_index
  
  private
  
  def check_file_size
    throw(:abort) if file_size > 50.megabytes
  end
  
  def process_special_fields
    # Custom processing
  end
  
  def log_mapping_time
    start_time = Time.current
    yield
    Rails.logger.info "Metadata mapping took #{Time.current - start_time}s"
  end
  
  def update_search_index
    SearchIndexJob.perform_later(self)
  end
end
```

### 2. Event System

```ruby
# app/services/folio/metadata/event_dispatcher.rb
module Folio::Metadata
  class EventDispatcher
    include Singleton
    
    def initialize
      @listeners = Hash.new { |h, k| h[k] = [] }
    end
    
    # Register event listener
    def on(event, &block)
      @listeners[event] << block
    end
    
    # Trigger event
    def trigger(event, *args)
      @listeners[event].each do |listener|
        listener.call(*args)
      rescue => e
        Rails.logger.error "Event listener error: #{e.message}"
      end
    end
    
    # Remove all listeners for an event
    def off(event)
      @listeners.delete(event)
    end
  end
  
  # Convenience methods
  module Events
    def metadata_events
      EventDispatcher.instance
    end
    
    def on_metadata_extracted(&block)
      metadata_events.on(:metadata_extracted, &block)
    end
    
    def on_metadata_mapped(&block)
      metadata_events.on(:metadata_mapped, &block)
    end
    
    def on_metadata_saved(&block)
      metadata_events.on(:metadata_saved, &block)
    end
  end
end

# config/initializers/metadata_events.rb
include Folio::Metadata::Events

# Register global event handlers
on_metadata_extracted do |file, metadata|
  Rails.logger.info "Extracted #{metadata.keys.count} fields from #{file.file_name}"
  
  # Check for copyright issues
  if metadata["Copyright"]&.include?("Getty Images")
    AdminMailer.copyright_alert(file).deliver_later
  end
end

on_metadata_mapped do |file, mapped_data|
  # Track which fields were successfully mapped
  Folio::Analytics.track("metadata_mapped", {
    file_id: file.id,
    mapped_fields: mapped_data.keys,
    source_fields: file.file_metadata.keys
  })
end

on_metadata_saved do |file|
  # Trigger dependent processes
  Folio::ThumbnailGeneratorJob.perform_later(file)
  Folio::AiTaggingJob.perform_later(file) if file.keywords.blank?
end
```

### 3. ActiveSupport Notifications

```ruby
# app/models/folio/file/image.rb
class Folio::File::Image
  def extract_metadata!
    ActiveSupport::Notifications.instrument("extract_metadata.folio", file: self) do
      @raw_metadata = read_metadata_from_file
    end
    
    ActiveSupport::Notifications.instrument("map_metadata.folio", 
      file: self, 
      metadata: @raw_metadata
    ) do
      map_metadata_to_attributes(@raw_metadata)
    end
    
    ActiveSupport::Notifications.instrument("save_metadata.folio", file: self) do
      save!
    end
  end
end

# config/initializers/metadata_instrumentation.rb
ActiveSupport::Notifications.subscribe("extract_metadata.folio") do |name, start, finish, id, payload|
  duration = finish - start
  file = payload[:file]
  
  Rails.logger.info "[METADATA] Extracted in #{duration}s for #{file.file_name}"
  
  # Send to monitoring service
  StatsD.timing("folio.metadata.extraction_time", duration * 1000)
  StatsD.increment("folio.metadata.extractions")
end

ActiveSupport::Notifications.subscribe("map_metadata.folio") do |name, start, finish, id, payload|
  if payload[:metadata].blank?
    Rails.logger.warn "[METADATA] No metadata to map for file ##{payload[:file].id}"
  end
end
```

## Testing Tools

### 1. Test Helpers

```ruby
# test/support/metadata_test_helper.rb
module MetadataTestHelper
  # Create file with specific metadata
  def create_image_with_metadata(metadata = {})
    file = Folio::File::Image.new(site: get_any_site)
    
    # Mock the metadata extraction
    file.stub(:read_metadata_from_file, metadata) do
      file.file = fixture_file("test.jpg")
      file.save!
    end
    
    file
  end
  
  # Assert metadata was extracted correctly
  def assert_metadata_extracted(file, expected)
    expected.each do |field, value|
      assert_equal value, file.send(field),
        "Expected #{field} to be '#{value}' but was '#{file.send(field)}'"
    end
  end
  
  # Test metadata mapping
  def with_metadata_mapping(mapping)
    original = Rails.application.config.folio_image_metadata_mappings
    Rails.application.config.folio_image_metadata_mappings = mapping
    yield
  ensure
    Rails.application.config.folio_image_metadata_mappings = original
  end
  

end
```

### 2. Factory Support

```ruby
# test/factories/metadata_factories.rb
FactoryBot.define do
  factory :iptc_metadata, class: Hash do
    initialize_with { attributes.stringify_keys }
    
    Artist { "John Photographer" }
    Copyright { "© 2024 Photography Inc." }
    Caption { "Test image caption" }
    Keywords { ["test", "sample", "metadata"] }
    City { "Prague" }
    Country { "Czech Republic" }
    GPSLatitude { "50.0755° N" }
    GPSLongitude { "14.4378° E" }
  end
  

  factory :image_with_full_metadata, parent: :folio_file_image do
    after(:build) do |image|
      image.file_metadata = build(:iptc_metadata)
    end
    
    after(:create) do |image|
      image.extract_metadata!
    end
  end
end
```

### 3. Matchers

```ruby
# test/support/matchers/metadata_matchers.rb
module MetadataMatchers
  class HaveExtractedMetadata
    def initialize(expected)
      @expected = expected
    end
    
    def matches?(file)
      @file = file
      @expected.all? do |field, value|
        file.send(field) == value
      end
    end
    
    def failure_message
      "expected #{@file} to have extracted metadata #{@expected}"
    end
    
    def failure_message_when_negated
      "expected #{@file} not to have extracted metadata #{@expected}"
    end
  end
  
  def have_extracted_metadata(expected)
    HaveExtractedMetadata.new(expected)
  end
  
  # Usage:
  # expect(image).to have_extracted_metadata(
  #   author: "John Doe",
  #   keywords: "nature, landscape"
  # )
end

RSpec.configure do |config|
  config.include MetadataMatchers
end
```

### 4. Integration Test Suite

```ruby
# test/integration/metadata_extraction_test.rb
class MetadataExtractionIntegrationTest < ActionDispatch::IntegrationTest
  include MetadataTestHelper
  
  test "full metadata extraction workflow" do
    # 1. Upload image with metadata
    post folio.console_files_path, params: {
      file: fixture_file_upload("photos/with_metadata.jpg")
    }
    
    assert_response :success
    file = Folio::File::Image.last
    
    # 2. Verify metadata was extracted
    assert_metadata_extracted(file,
      author: "Test Photographer",
      description: "Test Description",
      keywords: "test, metadata"
    )
    
    # 3. Check events were triggered
    assert_enqueued_with(job: Folio::ThumbnailGeneratorJob, args: [file])
    
    # 4. Verify in admin interface
    get folio.edit_console_file_path(file)
    assert_response :success
    assert_select "input[name='file[author]'][value='Test Photographer']"
  end
  

end
```

### 5. Performance Testing

```ruby
# test/performance/metadata_extraction_benchmark.rb
require "benchmark/ips"

class MetadataExtractionBenchmark < ActiveSupport::TestCase
  def setup
    @small_metadata = build(:iptc_metadata)
    @large_metadata = build(:iptc_metadata).merge(
      100.times.map { |i| ["CustomField#{i}", "Value#{i}"] }.to_h
    )
  end
  
  test "extraction performance" do
    Benchmark.ips do |x|
      x.report("small metadata") do
        extractor = Folio::Metadata::IptcMapper.new
        extractor.map_from_iptc(@small_metadata)
      end
      
      x.report("large metadata") do
        extractor = Folio::Metadata::IptcMapper.new
        extractor.map_from_iptc(@large_metadata)
      end
      
      x.compare!
    end
  end
  
  test "memory usage" do
    require "memory_profiler"
    
    report = MemoryProfiler.report do
      100.times do
        create_image_with_metadata(@large_metadata)
      end
    end
    
    assert report.total_allocated_memsize < 50.megabytes,
      "Memory usage too high: #{report.total_allocated_memsize / 1.megabyte}MB"
  end
end
```

## Console Commands

```ruby
# lib/tasks/folio_metadata_dev.rake
namespace :folio do
  namespace :metadata do
    desc "Test metadata extraction for a file"
    task :test, [:file_id] => :environment do |t, args|
      file = Folio::File.find(args[:file_id])
      
      puts "Testing metadata extraction for: #{file.file_name}"
      puts "=" * 50
      
      # Extract raw metadata
      metadata = Dragonfly.app.fetch(file.file_uid).metadata
      
      puts "Raw metadata (#{metadata.keys.count} fields):"
      metadata.each do |key, value|
        puts "  #{key}: #{value.to_s.truncate(100)}"
      end
      
      puts "\nMapped fields:"
      mapper = Folio::Metadata::IptcMapper.new
      mapped = mapper.map_from_iptc(metadata)
      mapped.each do |key, value|
        puts "  #{key}: #{value}"
      end
      
      puts "\nWould update:" 
      mapped.each do |key, value|
        if file.send(key).blank?
          puts "  ✓ #{key}: #{value}"
        else
          puts "  ✗ #{key}: already has '#{file.send(key)}'"
        end
      end
    end
    
    desc "Validate metadata configuration"
    task validate_config: :environment do
      config = Rails.application.config
      
      puts "Metadata Configuration:"
      puts "  Extraction enabled: #{config.folio_image_metadata_extraction_enabled}"
      puts "  Copy to placements: #{config.folio_image_metadata_copy_to_placements}"
      
      if config.folio_image_metadata_mappings.present?
        puts "\nCustom mappings:"
        config.folio_image_metadata_mappings.each do |field, sources|
          puts "  #{field}: #{sources.join(', ')}"
        end
      end
      
      puts "\nExiftool status:"
      if system("which exiftool > /dev/null 2>&1")
        puts "  ✓ Exiftool installed"
        puts "  Version: #{`exiftool -ver`.strip}"
      else
        puts "  ✗ Exiftool not found!"
      end
    end
  end
end
```
