# frozen_string_literal: true

namespace :folio do
  namespace :images do
    desc "Queue metadata extraction jobs for images without extracted metadata"
    task extract_metadata: :environment do
      unless Rails.application.config.folio_image_metadata_extraction_enabled
        puts "Metadata extraction is disabled. Enable it in config/initializers/folio_image_metadata.rb"
        exit 1
      end

      puts "Queuing metadata extraction jobs for images without extracted metadata..."

      # Find images without extracted metadata
      images_without_metadata = Folio::File::Image.where(file_metadata_extracted_at: nil)
                                                  .where.not(file_uid: nil)

      total_count = images_without_metadata.count

      if total_count == 0
        puts "No images found that need metadata extraction."
        exit 0
      end

      puts "Found #{total_count} images without extracted metadata."
      print "Queuing jobs"

      queued_count = 0

      images_without_metadata.find_each do |image|
        # Queue extraction job (background processing)
        Folio::Metadata::ExtractionJob.perform_later(image)
        queued_count += 1

        print "."

        # Progress indicator every 50 images
        if queued_count % 50 == 0
          puts " #{queued_count}/#{total_count}"
          print "Queuing jobs"
        end
      end

      puts "\n\nQueued #{queued_count} metadata extraction jobs."
      puts "Jobs will be processed in background. Check job queue status for progress."
    end

    desc "Show metadata extraction statistics"
    task metadata_stats: :environment do
      puts "Image Metadata Extraction Statistics"
      puts "=" * 40

      total_images = Folio::File::Image.count
      puts "Total images: #{total_images}"

      if total_images == 0
        puts "No images found."
        exit 0
      end

      # Check extraction status
      extracted_count = Folio::File::Image.where.not(file_metadata_extracted_at: nil).count
      pending_count = total_images - extracted_count

      puts "\nExtraction status:"
      puts "  Extracted: #{extracted_count}/#{total_images} (#{(extracted_count.to_f / total_images * 100).round(1)}%)"
      puts "  Pending: #{pending_count}/#{total_images} (#{(pending_count.to_f / total_images * 100).round(1)}%)"

      # Check database field coverage
      fields_stats = {
        headline: Folio::File::Image.where.not(headline: [nil, ""]).count,
        description: Folio::File::Image.where.not(description: [nil, ""]).count,
        gps_coordinates: Folio::File::Image.where.not(gps_latitude: nil, gps_longitude: nil).count
      }

      puts "\nDatabase field coverage:"
      fields_stats.each do |field, count|
        percentage = total_images > 0 ? (count.to_f / total_images * 100).round(1) : 0
        puts "  #{field}: #{count}/#{total_images} (#{percentage}%)"
      end

      # Configuration check
      puts "\nConfiguration:"
      puts "  Extraction enabled: #{Rails.application.config.folio_image_metadata_extraction_enabled}"

      # ExifTool availability (through Dragonfly)
      exiftool_available = system("which exiftool > /dev/null 2>&1")
      puts "  ExifTool available: #{exiftool_available}"

      puts "\nTo queue extraction jobs for pending images:"
      puts "  rails folio:images:extract_metadata"
    end
  end
end
