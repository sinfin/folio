# frozen_string_literal: true

namespace :folio do
  namespace :images do
    desc "Extract IPTC metadata for existing images"
    task extract_metadata: :environment do
      puts "Starting metadata extraction for existing images..."

      total_count = 0
      processed_count = 0
      error_count = 0

      Folio::File::Image.find_each do |image|
        total_count += 1

        begin
          # Skip if key metadata is already present
          if image.creator.present? && image.description.present? && image.headline.present?
            print "."
            next
          end

          # Extract metadata
          image.extract_metadata!
          processed_count += 1
          print "+"
        rescue => e
          error_count += 1
          puts "\nError processing #{image.file_name}: #{e.message}"
          print "E"
        end

        # Progress indicator every 50 images
        if total_count % 50 == 0
          puts "\nProcessed: #{total_count} images (#{processed_count} updated, #{error_count} errors)"
        end
      end

      puts "\n\nMetadata extraction complete!"
      puts "Total images: #{total_count}"
      puts "Updated: #{processed_count}"
      puts "Errors: #{error_count}"
    end

    desc "Extract IPTC metadata with namespace support (force re-extraction)"
    task extract_metadata_force: :environment do
      puts "Starting FORCED metadata extraction with IPTC namespace support..."

      total_count = 0
      processed_count = 0
      error_count = 0

      Folio::File::Image.find_each do |image|
        total_count += 1

        begin
          next unless image.file.present? && File.exist?(image.file.path)

          # Force re-extraction by temporarily clearing a field
          original_headline = image.headline
          image.headline = nil

          # Extract with namespace grouping
          require "open3"
          stdout, stderr, status = Open3.capture3(
            "exiftool", "-j", "-G1", "-struct", "-n", image.file.path
          )

          if status.success?
            metadata = JSON.parse(stdout).first
            image.map_iptc_metadata(metadata)

            # Restore original headline if extraction didn't find anything
            image.headline = original_headline if image.headline.blank?

            if image.changed?
              image.save!
              processed_count += 1
              print "+"
            else
              print "."
            end
          else
            error_count += 1
            puts "\nError processing #{image.file_name}: #{stderr}"
            print "E"
          end
        rescue => e
          error_count += 1
          puts "\nError processing #{image.file_name}: #{e.message}"
          print "E"
        end

        # Progress indicator every 50 images
        if total_count % 50 == 0
          puts "\nProcessed: #{total_count} images (#{processed_count} updated, #{error_count} errors)"
        end
      end

      puts "\n\nForced IPTC metadata extraction complete!"
      puts "Total images: #{total_count}"
      puts "Updated: #{processed_count}"
      puts "Errors: #{error_count}"
    end

    desc "Show metadata extraction statistics"
    task metadata_stats: :environment do
      puts "Image Metadata Extraction Statistics"
      puts "=" * 40

      total_images = Folio::File::Image.count
      puts "Total images: #{total_images}"

      # Check various metadata fields
      fields_stats = {
        headline: Folio::File::Image.where.not(headline: [nil, ""]).count,
        creator: Folio::File::Image.where("creator != '[]' AND creator IS NOT NULL").count,
        description: Folio::File::Image.where.not(description: [nil, ""]).count,
        keywords: Folio::File::Image.where("keywords != '[]' AND keywords IS NOT NULL").count,
        copyright_notice: Folio::File::Image.where.not(copyright_notice: [nil, ""]).count,
        gps_coordinates: Folio::File::Image.where.not(gps_latitude: nil, gps_longitude: nil).count,
        camera_info: Folio::File::Image.where.not(camera_make: [nil, ""]).count
      }

      puts "\nMetadata field coverage:"
      fields_stats.each do |field, count|
        percentage = total_images > 0 ? (count.to_f / total_images * 100).round(1) : 0
        puts "  #{field}: #{count}/#{total_images} (#{percentage}%)"
      end

      # Configuration check
      puts "\nConfiguration:"
      puts "  Extraction enabled: #{Rails.application.config.folio_image_metadata_extraction_enabled}"
      puts "  IPTC standard: #{Rails.application.config.folio_image_metadata_use_iptc_standard}"
      puts "  Copy to placements: #{Rails.application.config.folio_image_metadata_copy_to_placements}"

      # ExifTool availability
      exiftool_available = system("which exiftool > /dev/null 2>&1")
      puts "  ExifTool available: #{exiftool_available}"
    end

    desc "Test metadata extraction on a single image"
    task :test_extraction, [:image_id] => :environment do |_task, args|
      image_id = args[:image_id]

      if image_id.blank?
        puts "Usage: rake folio:images:test_extraction[IMAGE_ID]"
        exit 1
      end

      image = Folio::File::Image.find(image_id)
      puts "Testing metadata extraction for: #{image.file_name}"
      puts "Current metadata fields:"

      # Show current state
      %w[headline creator description keywords copyright_notice camera_make capture_date].each do |field|
        value = image.send(field)
        puts "  #{field}: #{value.inspect}"
      end

      puts "\nExtracting metadata..."
      image.extract_metadata!

      puts "Updated metadata fields:"
      %w[headline creator description keywords copyright_notice camera_make capture_date].each do |field|
        value = image.send(field)
        puts "  #{field}: #{value.inspect}"
      end

      if image.changed?
        puts "\nSaving changes..."
        image.save!
        puts "Done!"
      else
        puts "\nNo changes detected."
      end
    end
  end
end
