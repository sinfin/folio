# frozen_string_literal: true

require "test_helper"

class Folio::CloudflareStream::MonitorProcessingJobTest < ActiveJob::TestCase
  test "schedules progress checks for stale processing Stream videos" do
    video = create_video(
      "uid" => "stream-1",
      "processing_state" => "processing",
      "last_progress_check_at" => 10.minutes.ago.iso8601,
    )

    assert_enqueued_jobs 1, only: Folio::CloudflareStream::CheckProgressJob do
      monitor.perform
    end
  end

  test "does not schedule progress checks for recently checked Stream videos" do
    create_video(
      "uid" => "stream-1",
      "processing_state" => "processing",
      "last_progress_check_at" => 1.minute.ago.iso8601,
    )

    assert_no_enqueued_jobs only: Folio::CloudflareStream::CheckProgressJob do
      monitor.perform
    end
  end

  test "does not schedule progress checks without Stream uid" do
    create_video(
      "processing_state" => "processing",
      "last_progress_check_at" => 10.minutes.ago.iso8601,
    )

    assert_no_enqueued_jobs only: Folio::CloudflareStream::CheckProgressJob do
      monitor.perform
    end
  end

  test "logs monitor summary and scheduled video ids" do
    video = create_video(
      "uid" => "stream-1",
      "processing_state" => "processing",
      "last_progress_check_at" => 10.minutes.ago.iso8601,
    )

    log_io = StringIO.new
    logger = ActiveSupport::Logger.new(log_io)

    Rails.stub(:logger, logger) do
      monitor.perform
    end

    assert_includes log_io.string, "[CloudflareStream::MonitorProcessingJob] Started"
    assert_includes log_io.string, "Scheduling CheckProgressJob for video ##{video.id}"
    assert_includes log_io.string, "Finished scheduled=1"
  end

  private
    def monitor
      Folio::CloudflareStream::MonitorProcessingJob.new
    end

    def create_video(remote_services_data)
      video = create(:folio_file_video)
      video.update_columns(
        aasm_state: "processing",
        updated_at: 10.minutes.ago,
        remote_services_data: {
          "service" => "cloudflare_stream",
          "encoding_generation" => 123,
        }.merge(remote_services_data),
      )
      video
    end
end
