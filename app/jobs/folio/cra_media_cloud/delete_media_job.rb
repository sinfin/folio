# frozen_string_literal: true

class Folio::CraMediaCloud::DeleteMediaJob < Folio::ApplicationJob
  queue_as :slow

  def perform(id, reference_id: nil)
    if id.blank? && reference_id.blank?
      Rails.logger.warn "[CraMediaCloud::DeleteMediaJob] Skipping — no remote_id or reference_id (file was never processed by CRA)"
      return
    end

    if reference_id.present?
      # Prefer reference_id — deletes all phase jobs (multi-phase encoding creates multiple jobs per ref)
      jobs = api.get_jobs(ref_id: reference_id)

      if jobs.any?
        jobs.each do |job|
          Rails.logger.info "[CraMediaCloud::DeleteMediaJob] Deleting job content for job ID #{job['id']} (ref: #{reference_id})"
          safe_delete_job_content(job["id"])
        end
        Rails.logger.info "[CraMediaCloud::DeleteMediaJob] Deleted content for #{jobs.size} job(s) with reference_id #{reference_id}"
      end
    elsif id.present?
      safe_delete_job_content(id)
    end
  end

  private
    def safe_delete_job_content(job_id)
      api.delete_job_content(job_id)
    rescue RuntimeError => e
      # CRA returns 400 when content was already deleted — that's fine, goal achieved
      if e.message.include?("status 400") || e.message.include?("status 404")
        Rails.logger.info "[CraMediaCloud::DeleteMediaJob] Job #{job_id} content already removed (#{e.message})"
      else
        raise
      end
    end

    def api
      @api ||= Folio::CraMediaCloud::Api.new
    end
end
