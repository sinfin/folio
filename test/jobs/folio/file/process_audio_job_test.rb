# frozen_string_literal: true

require "test_helper"

class Folio::File::ProcessAudioJobTest < ActiveJob::TestCase
  class SuccessfulAudioProcessingService
    def initialize(audio_file)
      @audio_file = audio_file
    end

    def call
      @audio_file.processing_done!
    end
  end

  test "retries processing_failed audio through processing state" do
    audio = create(:folio_file_audio)
    audio.update_column(:aasm_state, "processing_failed")

    service = -> (audio_file) { SuccessfulAudioProcessingService.new(audio_file) }

    Folio::File::AudioProcessingService.stub(:new, service) do
      Folio::File::ProcessAudioJob.perform_now(audio)
    end

    assert_equal "ready", audio.reload.aasm_state
  end
end
