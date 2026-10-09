# frozen_string_literal: true

require "test_helper"

class Folio::Files::RestartProcessingMediaJobTest < ActiveJob::TestCase
  test "skips processing audio that lacks media processing state" do
    audio = create(:folio_file_audio)
    audio.update_columns(aasm_state: "processing",
                         remote_services_data: { "error" => "worker killed" })

    clear_enqueued_jobs

    # Before the fix this raised NoMethodError (audio has no #processing_state)
    Folio::Files::RestartProcessingMediaJob.perform_now

    assert_equal "processing", audio.reload.aasm_state
    assert_no_enqueued_jobs
  end
end
