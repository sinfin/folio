# frozen_string_literal: true

class Folio::File::BatchDownloadJob < Folio::ApplicationJob
  include Folio::S3::Client

  S3_FILE_LIFESPAN = 15.minutes

  queue_as :slow

  if defined?(sidekiq_options)
    sidekiq_options retry: false
  end

  def perform(s3_path:, file_class_name:, file_ids:, user_id:, site_id:)
    file_klass = file_class_name.constantize
    raise "Unknown file_klass - #{file_class_name}" unless file_klass < Folio::File

    site = Folio::Site.find(site_id)
    user = Folio::User.find(user_id)
    ability = Folio::Ability.new(user, site)

    files = file_klass.accessible_by(ability).where(id: file_ids).to_a

    tmp_zip_file = Tempfile.new("folio-files")

    Zip::File.open(tmp_zip_file.path, Zip::File::CREATE) do |zip|
      files.each do |file|
        # dragonfly ¯\_(ツ)_/¯
        tmp_file = file.file.file
        zip.add("#{file.id}-#{file.file_name}", tmp_file)
      end
    end

    test_aware_s3_upload(s3_path:, file: File.open(tmp_zip_file, "rb"), acl: "private")

    tmp_zip_file.close
    tmp_zip_file.unlink

    url = test_aware_presign_url(s3_path:)

    Folio::S3::DeleteJob.set(wait: S3_FILE_LIFESPAN).perform_later(s3_path:)

    MessageBus.publish Folio::MESSAGE_BUS_CHANNEL,
                       {
                         type: "Folio::File::BatchDownloadJob/success",
                         data: { url: },
                       }.to_json,
                       user_ids: [user.id]
  rescue StandardError => e
    MessageBus.publish Folio::MESSAGE_BUS_CHANNEL,
                       {
                         type: "Folio::File::BatchDownloadJob/failure",
                         data: { message: "#{e.message[0..96]}..." },
                       }.to_json,
                       user_ids: [user.id]
  end
end
