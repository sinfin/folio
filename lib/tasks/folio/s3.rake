# frozen_string_literal: true

namespace :folio do
  namespace :s3 do
    task update_schedule_yml: :environment do
      schedule_yml_path = Rails.root.join("config/schedule.yml")

      unless File.exist?(schedule_yml_path)
        File.open(schedule_yml_path, "w") { }
      end

      contents = File.read(schedule_yml_path)

      if contents.include?("Folio::S3::ClearMultipartUploadsJob")
        puts "Skipping as config/schedule.yml already includes Folio::S3::ClearMultipartUploadsJob"
      else
        yml = <<~YML
          folio_s3_clear_multipart_uploads:
            cron: "0 */4 * * *"
            class: Folio::S3::ClearMultipartUploadsJob
            active_job: true
            date_as_argument: false
        YML

        File.write(schedule_yml_path, contents == "" ? yml : contents + "\n#{yml}")
        puts "Added Folio::S3::ClearMultipartUploadsJob to config/schedule.yml"
      end
    end

    task clear_all_multipart_uploads: :environment do
      Folio::S3::ClearMultipartUploadsJob.perform_now(all: true)
    end
  end
end
