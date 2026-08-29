# frozen_string_literal: true

require "test_helper"

class Folio::File::ProcessAudioJobTest < ActiveJob::TestCase
  test "retries processing_failed audio through processing state" do
    audio = create(:folio_file_audio)
    audio.update_column(:aasm_state, "processing_failed")

    service = Folio::File::AudioProcessingService.new(audio)

    service.stub(:call, -> { audio.processing_done! }) do
      Folio::File::AudioProcessingService.stub(:new, -> (_audio_file) { service }) do
        Folio::File::ProcessAudioJob.perform_now(audio)
      end
    end

    assert_equal "ready", audio.reload.aasm_state
  end

  test "keeps processed audio ready when success broadcast fails" do
    audio = create(:folio_file_audio)
    audio.update_column(:aasm_state, "processing")

    service = Folio::File::AudioProcessingService.new(audio)
    job = Folio::File::ProcessAudioJob.new

    service.stub(:call, -> { audio.processing_done! }) do
      Folio::File::AudioProcessingService.stub(:new, -> (_audio_file) { service }) do
        job.stub(:broadcast_file_update, -> (_audio_file) { raise "broadcast failed" }) do
          assert_nothing_raised do
            job.perform(audio)
          end
        end
      end
    end

    audio.reload
    assert_equal "ready", audio.aasm_state
    assert_nil audio.remote_services_data.to_h["error"]
  end
end
