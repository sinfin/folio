# IPTC Metadata Performance & Testing

## Performance Optimizations

### ExifTool Stay-Open Mode

For bulk processing, use ExifTool's stay-open mode to avoid per-file process spawn overhead:

```ruby
# app/services/folio/metadata/bulk_extractor.rb
module Folio::Metadata
  class BulkExtractor
    def initialize
      @exiftool_pid = nil
      @stdin = nil
      @stdout = nil
      @stderr = nil
    end
    
    def start_exiftool
      return if @exiftool_pid
      
      @stdin, @stdout, @stderr, @wait_thr = Open3.popen3(
        "exiftool", "-stay_open", "True", "-@", "-"
      )
      @exiftool_pid = @wait_thr.pid
    end
    
    def stop_exiftool
      return unless @exiftool_pid
      
      @stdin.puts("-stay_open\nFalse\n")
      @stdin.close
      @stdout.close
      @stderr.close
      Process.wait(@exiftool_pid)
      @exiftool_pid = nil
    end
    
    def extract_batch(file_paths)
      start_exiftool
      results = {}
      
      file_paths.each do |path|
        # Send command to stay-open ExifTool
        @stdin.puts("-j")
        @stdin.puts("-G1")
        @stdin.puts("-struct")
        @stdin.puts("-n")
        @stdin.puts(path)
        @stdin.puts("-execute\n")
        @stdin.flush
        
        # Read response until {ready}
        output = ""
        while line = @stdout.gets
          break if line.strip == "{ready}"
          output << line
        end
        
        # Parse JSON response
        begin
          json_data = JSON.parse(output)
          results[path] = json_data.first if json_data.any?
        rescue JSON::ParserError => e
          Rails.logger.error "Failed to parse ExifTool output for #{path}: #{e.message}"
        end
      end
      
      results
    ensure
      stop_exiftool
    end
  end
end
```

### Batch Processing Job

```ruby
# app/jobs/folio/metadata_extraction_job.rb
class Folio::MetadataExtractionJob < ApplicationJob
  queue_as :low
  
  def perform(batch_size: 100)
    extractor = Folio::Metadata::BulkExtractor.new
    
    Folio::File::Image.where(file_metadata_extracted_at: nil)
                      .find_in_batches(batch_size: batch_size) do |batch|
      
      # Collect file paths
      file_paths = batch.map { |img| img.file.path }.compact
      
      # Extract metadata in bulk
      metadata_results = extractor.extract_batch(file_paths)
      
      # Update records
      batch.each do |image|
        next unless metadata = metadata_results[image.file.path]
        
        mapped_fields = Folio::Metadata::IptcFieldMapper.map_metadata(metadata)
        
        # Only update blank fields
        update_fields = {}
        mapped_fields.each do |field, value|
          if image.send(field).blank? && value.present?
            update_fields[field] = value
          end
        end
        
        if update_fields.any?
          update_fields[:file_metadata_extracted_at] = Time.current
          image.update_columns(update_fields)
        end
      end
    end
  ensure
    extractor&.stop_exiftool
  end
end
```

## Test Suite

### 1. Lang Alt Resolution Tests

```ruby
# test/services/folio/metadata/lang_alt_test.rb
require 'test_helper'

class Folio::Metadata::LangAltTest < ActiveSupport::TestCase
  setup do
    @mapper = Folio::Metadata::IptcFieldMapper
  end
  
  test "resolves Lang Alt with configurable locale priority" do
    metadata = {
      "XMP-dc:description" => {
        "en" => "English description",
        "cs" => "Český popis",
        "de" => "Deutsche Beschreibung",
        "x-default" => "Default description"
      }
    }
    
    # Configure Czech priority
    with_config(folio_image_metadata_locale_priority: [:cs, :en, "x-default"]) do
      # Should prefer Czech when available
      result = @mapper.map_metadata(metadata)
      assert_equal "Český popis", result[:description]
    end
    
    # Configure English priority
    with_config(folio_image_metadata_locale_priority: [:en, :cs, "x-default"]) do
      result = @mapper.map_metadata(metadata)
      assert_equal "English description", result[:description]
    end
    
    # Test missing locale falls back in priority order
    with_config(folio_image_metadata_locale_priority: [:fr, :cs, :en, "x-default"]) do
      result = @mapper.map_metadata(metadata)
      assert_equal "Český popis", result[:description]  # French missing, Czech is next
    end
  end
  
  test "handles regional variants in Lang Alt" do
    metadata = {
      "XMP-dc:title" => {
        "en-US" => "American Title",
        "en-GB" => "British Title",
        "cs-CZ" => "Český titulek",
        "cs" => "Obecný český titulek"
      }
    }
    
    with_config(folio_image_metadata_locale_priority: [:cs, :en]) do
      result = @mapper.map_metadata(metadata)
      # Should prefer exact "cs" match over "cs-CZ"
      assert_equal "Obecný český titulek", result[:headline]
    end
    
    # When only regional variant exists
    metadata_regional = {
      "XMP-photoshop:Headline" => {
        "en-US" => "US Headline",
        "cs-CZ" => "CZ Headline"
      }
    }
    
    with_config(folio_image_metadata_locale_priority: [:cs, :en]) do
      result = @mapper.map_metadata(metadata_regional)
      # Should find "cs-CZ" when "cs" not available
      assert_equal "CZ Headline", result[:headline]
    end
  end
  
  test "handles simple string when Lang Alt expected" do
    metadata = {
      "XMP-dc:description" => "Simple string description"
    }
    
    result = @mapper.map_metadata(metadata)
    assert_equal "Simple string description", result[:description]
  end
  
  private
  
  def with_config(options)
    original = {}
    options.each do |key, value|
      original[key] = Rails.application.config.send(key)
      Rails.application.config.send("#{key}=", value)
    end
    yield
  ensure
    original.each do |key, value|
      Rails.application.config.send("#{key}=", value)
    end
  end
end
```

### 2. JSONB Array Tests

```ruby
# test/services/folio/metadata/jsonb_arrays_test.rb
require 'test_helper'

class Folio::Metadata::JsonbArraysTest < ActiveSupport::TestCase
  setup do
    @mapper = Folio::Metadata::IptcFieldMapper
  end
  
  test "keeps keywords as JSONB array, not concatenated string" do
    metadata = {
      "XMP-dc:subject" => ["nature", "landscape", "photography"]
    }
    
    result = @mapper.map_metadata(metadata)
    assert_equal ["nature", "landscape", "photography"], result[:keywords]
    assert_instance_of Array, result[:keywords]
  end
  
  test "handles single keyword string" do
    metadata = {
      "XMP-dc:subject" => "single-keyword"
    }
    
    result = @mapper.map_metadata(metadata)
    assert_equal ["single-keyword"], result[:keywords]
  end
  
  test "keeps creator as array for multiple names" do
    metadata = {
      "XMP-dc:creator" => ["John Doe", "Jane Smith"]
    }
    
    result = @mapper.map_metadata(metadata)
    assert_equal ["John Doe", "Jane Smith"], result[:creator]
  end
  
  test "stores structured location data as JSONB" do
    metadata = {
      "XMP-iptcExt:LocationCreated" => [
        {
          "City" => "Prague",
          "CountryCode" => "CZ",
          "CountryName" => "Czech Republic",
          "ProvinceState" => "Central Bohemia",
          "Sublocation" => "Old Town Square"
        }
      ]
    }
    
    result = @mapper.map_metadata(metadata)
    assert_instance_of Array, result[:location_created]
    assert_equal "Prague", result[:location_created].first["City"]
  end
end
```

### 3. Boolean and URL Type Tests

```ruby
# test/services/folio/metadata/field_types_test.rb
require 'test_helper'

class Folio::Metadata::FieldTypesTest < ActiveSupport::TestCase
  setup do
    @mapper = Folio::Metadata::IptcFieldMapper
  end
  
  test "copyright_marked stored as boolean" do
    # Test various truthy values
    [true, "true", "True", 1].each do |value|
      metadata = { "XMP-xmpRights:Marked" => value }
      result = @mapper.map_metadata(metadata)
      assert_equal true, result[:copyright_marked], "Failed for value: #{value.inspect}"
    end
    
    # Test various falsy values
    [false, "false", "False", 0].each do |value|
      metadata = { "XMP-xmpRights:Marked" => value }
      result = @mapper.map_metadata(metadata)
      assert_equal false, result[:copyright_marked], "Failed for value: #{value.inspect}"
    end
  end
  
  test "rights_usage_info stored as URL string" do
    metadata = {
      "XMP-xmpRights:WebStatement" => "https://example.com/rights"
    }
    
    result = @mapper.map_metadata(metadata)
    assert_equal "https://example.com/rights", result[:rights_usage_info]
    assert_instance_of String, result[:rights_usage_info]
  end
end
```

### 4. GPS and Timezone Tests

```ruby
# test/services/folio/metadata/gps_timezone_test.rb
require 'test_helper'

class Folio::Metadata::GpsTimezoneTest < ActiveSupport::TestCase
  setup do
    @mapper = Folio::Metadata::IptcFieldMapper
  end
  
  test "GPS decimal parsing with -n flag returns signed decimals" do
    # With -n flag, ExifTool returns signed decimal directly
    # No need for GPSLatitudeRef/GPSLongitudeRef
    metadata = {
      "GPSLatitude" => 50.0755,   # North (positive)
      "GPSLongitude" => 14.4378    # East (positive)
    }
    
    result = @mapper.map_metadata(metadata)
    assert_equal 50.0755, result[:gps_latitude]
    assert_equal 14.4378, result[:gps_longitude]
  end
  
  test "GPS negative values with -n flag" do
    # With -n flag, South and West are already negative
    metadata = {
      "GPSLatitude" => -33.7490,   # South (negative)
      "GPSLongitude" => -118.2437   # West (negative)
    }
    
    result = @mapper.map_metadata(metadata)
    assert_equal -33.7490, result[:gps_latitude]
    assert_equal -118.2437, result[:gps_longitude]
  end
  
  test "capture date with timezone preservation" do
    # ISO 8601 with timezone
    metadata = {
      "DateTimeOriginal" => "2024-03-15T14:30:00+02:00"
    }
    
    result = @mapper.map_metadata(metadata)
    assert_not_nil result[:capture_date]
    assert_equal Time.parse("2024-03-15T14:30:00+02:00"), result[:capture_date]
  end
  
  test "capture date precedence order" do
    metadata = {
      "DateTimeOriginal" => "2024-01-01T10:00:00",
      "XMP-photoshop:DateCreated" => "2024-01-02T11:00:00",
      "XMP-xmp:CreateDate" => "2024-01-03T12:00:00",
      "CreateDate" => "2024-01-04T13:00:00"
    }
    
    result = @mapper.map_metadata(metadata)
    # Should prefer DateTimeOriginal
    assert_equal Time.parse("2024-01-01T10:00:00"), result[:capture_date]
  end
end
```

### 5. Integration Tests

```ruby
# test/integration/folio/metadata_extraction_integration_test.rb
require 'test_helper'

class Folio::MetadataExtractionIntegrationTest < ActionDispatch::IntegrationTest
  test "full metadata extraction workflow with overwrite protection" do
    image = Folio::File::Image.create!(
      site: sites(:default),
      file: fixture_file_upload('test_with_metadata.jpg'),
      creator: ["Manual Creator"]  # Pre-existing data
    )
    
    # Extract metadata
    image.extract_iptc_metadata!
    
    # Should NOT overwrite existing creator
    assert_equal ["Manual Creator"], image.creator
    
    # Should extract other fields
    assert_present image.keywords
    assert_present image.capture_date
    assert_present image.camera_make
  end
  
  test "bulk extraction performance" do
    # Create 100 test images
    images = 100.times.map do
      Folio::File::Image.create!(
        site: sites(:default),
        file: fixture_file_upload('test.jpg')
      )
    end
    
    # Measure bulk extraction time
    time = Benchmark.realtime do
      Folio::MetadataExtractionJob.perform_now(batch_size: 50)
    end
    
    # Should process 100 images in reasonable time
    assert time < 10, "Bulk extraction took #{time}s, expected < 10s"
    
    # Verify extraction
    images.each(&:reload)
    assert images.all? { |img| img.file_metadata_extracted_at.present? }
  end
  
  test "admin re-extraction with overwrite option" do
    image = Folio::File::Image.create!(
      site: sites(:default),
      file: fixture_file_upload('test_with_metadata.jpg'),
      creator: ["Old Creator"],
      keywords: ["old", "keywords"]
    )
    
    # Admin force re-extraction
    patch admin_file_path(image), params: {
      file: { 
        re_extract_metadata: true,
        overwrite_protected_fields: true
      }
    }
    
    assert_response :redirect
    image.reload
    
    # Should overwrite with force flag
    assert_not_equal ["Old Creator"], image.creator
    assert_not_equal ["old", "keywords"], image.keywords
  end
end
```

## Command Line Verification

```bash
# Verify ExifTool with namespace grouping
exiftool -j -G1 -struct -n test.jpg | jq '.[0] | keys | sort'

# Test Lang Alt structure
exiftool -j -G1 -struct test.jpg | jq '.[0]["XMP-dc:description"]'

# Performance test with multiple files
time exiftool -j -G1 -struct -n *.jpg > /tmp/bulk_test.json

# Stay-open mode test
echo -e "-j\n-G1\n-struct\n-n\ntest.jpg\n-execute\n-stay_open\nFalse" | exiftool -stay_open True -@ -
```

## Benchmarks

```ruby
# test/benchmarks/metadata_extraction_benchmark.rb
require 'benchmark/ips'

class MetadataExtractionBenchmark < Minitest::Benchmark
  def bench_single_file_extraction
    assert_performance_linear 0.99 do |n|
      n.times do
        metadata = extract_with_exiftool("test.jpg")
        Folio::Metadata::IptcFieldMapper.map_metadata(metadata)
      end
    end
  end
  
  def bench_stay_open_vs_spawn
    Benchmark.ips do |x|
      x.report("spawn per file") do
        10.times do |i|
          `exiftool -j -G1 -struct -n test#{i}.jpg`
        end
      end
      
      x.report("stay-open mode") do
        extractor = Folio::Metadata::BulkExtractor.new
        paths = 10.times.map { |i| "test#{i}.jpg" }
        extractor.extract_batch(paths)
      end
      
      x.compare!
    end
  end
end
```

---

*This test suite ensures IPTC-compliant metadata extraction with proper type handling, performance optimization, and data integrity.*
