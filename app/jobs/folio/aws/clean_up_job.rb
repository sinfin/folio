# frozen_string_literal: true

# Removes orphan records from DB and from S3. It completely deletes s3_path directory
class Folio::Aws::CleanUpJob < Folio::ApplicationJob
  include Folio::S3::Client

  FILE_MODELS = Rails.application.config.folio_direct_s3_upload_class_names.map(&:safe_constantize)

  # Remove unfinished records older than
  OBSOLETE_INTERVAL = 24.hours

  queue_as :default

  def perform
    FILE_MODELS.each do |model_name|
      # TODO: Think about situation of reprocess flow. Example: We have ready file that we want to reprocess, but for
      #       some reason AWS flow fails and we never receive notification about processed metadata. Currently i'm
      #       trying to solve this issue by checking how old created_at is and if it is older by more than 1.hour than
      #       updated_at we don't remove this file
      model_name
        .where(updated_at: ..(Time.current - OBSOLETE_INTERVAL), aasm_state: Folio::Aws::FileProcessable::NON_TERMINAL_STATES)
        .where("updated_at < created_at + INTERVAL '1 HOUR'").each do |file|
        # Delete all content in s3_path directory
        Folio::Aws::S3::FileService.delete_all(file.s3_path)
        file.destroy!
      rescue StandardError => e
        # TODO: Do something more than just log
        Rails.logger.error("Error deleting file #{file.s3_path}: #{e.message}")
      end
    end
  end
end
