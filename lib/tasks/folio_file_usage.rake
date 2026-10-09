# frozen_string_literal: true

namespace :folio do
  namespace :files do
    desc "Recalculate stale placement counters. DRY_RUN=1 lists ids only. ALL_VIDEOS=1 also recalcs every video."
    task recalculate_placement_counts: :environment do
      mismatched_ids = Folio::File.where(
        "folio_files.file_placements_count <> " \
        "(SELECT COUNT(*) FROM folio_file_placements fp WHERE fp.file_id = folio_files.id)"
      ).pluck(:id)

      puts "Files with stale file_placements_count: #{mismatched_ids.size}"

      if ENV["DRY_RUN"].present?
        puts mismatched_ids.inspect
      else
        Folio::File.where(id: mismatched_ids).find_each(&:update_file_placements_counts!)
        puts "Recalculated #{mismatched_ids.size} files."
      end

      if ENV["ALL_VIDEOS"].present? && ENV["DRY_RUN"].blank?
        count = 0

        Folio::File::Video.find_each do |video|
          video.update_file_placements_counts!
          count += 1
        end

        puts "Recalculated all #{count} videos."
      end
    end

    desc "CSV list of videos with no published usage (their public pages return 404)"
    task report_videos_without_published_usage: :environment do
      count = 0
      puts "id;slug;file_name"

      Folio::File::Video.find_each do |video|
        next if video.used_in_published_content?
        count += 1
        puts [video.id, video.slug, video.file_name].join(";")
      end

      warn "Total without published usage: #{count}"
    end
  end
end
