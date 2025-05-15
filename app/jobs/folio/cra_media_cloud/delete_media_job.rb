# frozen_string_literal: true

class Folio::CraMediaCloud::DeleteMediaJob < Folio::ApplicationJob
  queue_as :slow

  def perform(id, reference_id: nil)
    if id.present?
      api.delete_job_content(id)
    elsif reference_id.present?
      # media file processing in progress, check the status
      response = api.get_jobs(ref_id: reference_id).last

      if response.present?
        # processed, content can be deleted
        api.delete_job_content(response["id"])
      else
        # still not processed, wait
        Folio::CraMediaCloud::DeleteMediaJob.set(wait: 1.minute).perform_later(id, reference_id:)
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
