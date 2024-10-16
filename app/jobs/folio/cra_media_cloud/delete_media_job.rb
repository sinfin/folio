# frozen_string_literal: true

class Folio::CraMediaCloud::DeleteMediaJob < Folio::ApplicationJob
  queue_as :slow

  def perform(id)
    Folio::CraMediaCloud::Api.new.delete_job_content(id)
    # TODO: check response
  end
end
