# frozen_string_literal: true

class Folio::CraMediaCloud::DeleteMediaJob < Folio::ApplicationJob
  queue_as :slow

  def perform(id, reference_id: nil)
    if id.present?
      api.delete_job_content(id)
    elsif reference_id.present?
      # Get all jobs with this reference_id
      jobs = api.get_jobs(ref_id: reference_id)

      if jobs.any?
        # Delete content for all jobs with this reference_id
        jobs.each do |job|
          Rails.logger.info "[CraMediaCloud::DeleteMediaJob] Deleting job content for job ID #{job['id']} (ref: #{reference_id})"
          api.delete_job_content(job["id"])
        end
        Rails.logger.info "[CraMediaCloud::DeleteMediaJob] Deleted content for #{jobs.size} job(s) with reference_id #{reference_id}"
      end
    else
      raise "Missing remote_key and remote_reference_id"
    end
  end

  private
    def api
      @api ||= Folio::CraMediaCloud::Api.new
    end
end
