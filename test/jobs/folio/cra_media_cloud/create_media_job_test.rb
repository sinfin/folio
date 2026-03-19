# frozen_string_literal: true

require "test_helper"

class Folio::CraMediaCloud::CreateMediaJobTest < ActiveJob::TestCase
  class TestVideoFile < Folio::File::Video
    include Folio::CraMediaCloud::FileProcessing
  end

  test "passes encoding_generation to CheckProgressJob when uploading" do
    video = create_test_video_in_processing_state
    generation_value = 1700000000
    video.update!(remote_services_data: video.remote_services_data.merge(
      "encoding_generation" => generation_value
    ))

    with_mocked_s3_and_encoder(video) do |encoder_mock, api_mock|
      encoder_mock.expect(:upload_file, nil, [video], profile_group: nil, processing_phases: 1, reference_id: String)
      api_mock.expect(:get_jobs, [], [], ref_id: String)

      assert_enqueued_jobs 1, only: Folio::CraMediaCloud::CheckProgressJob do
        perform_job(video, encoder_mock, api_mock)
      end
    end

    video.reload
    assert_equal generation_value, video.encoding_generation,
      "encoding_generation should be preserved through CreateMediaJob"
  end

  test "submits single manifest and sets full_media_processing state" do
    video = create_test_video_in_processing_state

    with_mocked_s3_and_encoder(video) do |encoder_mock, api_mock|
      encoder_mock.expect(:upload_file, nil, [video], profile_group: nil, processing_phases: 1, reference_id: String)
      api_mock.expect(:get_jobs, [], [], ref_id: String)

      perform_job(video, encoder_mock, api_mock)
      encoder_mock.verify
    end

    video.reload
    assert_equal "full_media_processing", video.remote_services_data["processing_state"]
  end

  test "passes processing_phases to encoder when video defines it" do
    video = create_test_video_in_processing_state
    video.define_singleton_method(:encoder_processing_phases) { 2 }

    with_mocked_s3_and_encoder(video) do |encoder_mock, api_mock|
      encoder_mock.expect(:upload_file, nil, [video],
        profile_group: nil, processing_phases: 2, reference_id: String)
      api_mock.expect(:get_jobs, [], [], ref_id: String)

      assert_enqueued_jobs 1, only: Folio::CraMediaCloud::CheckProgressJob do
        perform_job(video, encoder_mock, api_mock)
      end

      encoder_mock.verify
    end

    video.reload
    assert_equal 2, video.remote_services_data["processing_phases"]
  end

  test "check_existing_job: DONE returns :done" do
    video = create_test_video_in_processing_state

    mock_api = Minitest::Mock.new
    mock_api.expect(:get_jobs, [
      { "id" => 1, "refId" => "test-abc123", "status" => "DONE",
        "profileGroup" => "VoD", "lastModified" => "2026-01-01T00:00:00Z",
        "messages" => [], "output" => [] },
    ], [], ref_id: "test-abc123")

    job_instance = Folio::CraMediaCloud::CreateMediaJob.new

    Folio::CraMediaCloud::Api.stub(:new, mock_api) do
      result = job_instance.send(:check_existing_job, "test-abc123", video)
      assert_equal :done, result[:status]
    end
  end

  test "check_existing_job: picks latest job when multiple exist" do
    video = create_test_video_in_processing_state

    mock_api = Minitest::Mock.new
    mock_api.expect(:get_jobs, [
      { "id" => 1, "refId" => "test-abc123", "status" => "FAILED",
        "profileGroup" => "VoD", "lastModified" => "2026-01-01T00:00:00Z",
        "messages" => [], "output" => [] },
      { "id" => 2, "refId" => "test-abc123", "status" => "DONE",
        "profileGroup" => "VoD", "lastModified" => "2026-01-02T00:00:00Z",
        "messages" => [], "output" => [] },
    ], [], ref_id: "test-abc123")

    job_instance = Folio::CraMediaCloud::CreateMediaJob.new

    Folio::CraMediaCloud::Api.stub(:new, mock_api) do
      result = job_instance.send(:check_existing_job, "test-abc123", video)
      assert_equal :done, result[:status]
      assert_equal 2, result[:job]["id"]
    end
  end

  test "check_existing_job: empty jobs returns :not_found" do
    video = create_test_video_in_processing_state

    mock_api = Minitest::Mock.new
    mock_api.expect(:get_jobs, [], [], ref_id: "test-abc123")

    job_instance = Folio::CraMediaCloud::CreateMediaJob.new

    Folio::CraMediaCloud::Api.stub(:new, mock_api) do
      result = job_instance.send(:check_existing_job, "test-abc123", video)
      assert_equal :not_found, result[:status]
    end
  end

  test "marks video as permanently failed when S3 source file is missing" do
    video = create_test_video_in_processing_state

    # Mock S3 datastore to raise NotFound (simulates missing source file)
    s3_datastore_mock = Minitest::Mock.new
    storage_mock = Minitest::Mock.new
    storage_mock.expect(:head_object, nil) do |*_args|
      raise Excon::Error::NotFound.new("Expected(200) <=> Actual(404 Not Found)")
    end
    s3_datastore_mock.expect(:root_path, "uploads")
    s3_datastore_mock.expect(:storage, storage_mock)

    ENV["S3_BUCKET_NAME"] = "test-bucket"
    begin
      Dragonfly.app.stub(:datastore, s3_datastore_mock) do
        assert_no_enqueued_jobs only: Folio::CraMediaCloud::CheckProgressJob do
          Folio::CraMediaCloud::CreateMediaJob.perform_now(video)
        end
      end
    ensure
      ENV.delete("S3_BUCKET_NAME")
    end

    video.reload
    assert_equal "processing_failed", video.aasm_state
    assert_equal "source_file_missing", video.remote_services_data["processing_state"]
    assert_includes video.remote_services_data["error_message"], "Source file not found"
  end

  test "retries from processing_failed state via retry_processing!" do
    video = create_test_video_in_processing_state
    video.update_column(:aasm_state, "processing_failed")
    video.update!(remote_services_data: video.remote_services_data.merge(
      "retry_count" => 1,
      "retry_scheduled_at" => Time.current.iso8601
    ))

    with_mocked_s3_and_encoder(video) do |encoder_mock, api_mock|
      encoder_mock.expect(:upload_file, nil, [video], profile_group: nil, processing_phases: 1, reference_id: String)
      api_mock.expect(:get_jobs, [], [], ref_id: String)

      assert_enqueued_jobs 1, only: Folio::CraMediaCloud::CheckProgressJob do
        perform_job(video, encoder_mock, api_mock)
      end
    end

    video.reload
    assert_equal "processing", video.aasm_state
    assert_equal "full_media_processing", video.remote_services_data["processing_state"]
  end

  private
    def create_test_video_in_processing_state(klass: TestVideoFile)
      video = klass.new(site: get_any_site)
      video.file = Folio::Engine.root.join("test/fixtures/folio/blank.mp4")
      video.dont_run_after_save_jobs = true

      expect_method_called_on(object: video, method: :create_full_media) do
        video.save!
      end

      video.update!(remote_services_data: video.remote_services_data.merge(
        "service" => "cra_media_cloud",
        "processing_state" => "full_media_processing"
      ))
      video
    end

    def with_mocked_s3_and_encoder(video)
      s3_metadata_mock = Struct.new(:etag).new('"abc12345def67890"')
      s3_datastore_mock = Minitest::Mock.new
      storage_mock = Minitest::Mock.new

      # head_object is called with bucket_name (ENV) and key — allow any args
      storage_mock.expect(:head_object, s3_metadata_mock) do |*_args|
        true
      end
      s3_datastore_mock.expect(:root_path, "uploads")
      s3_datastore_mock.expect(:storage, storage_mock)

      encoder_mock = Minitest::Mock.new
      api_mock = Minitest::Mock.new

      ENV["S3_BUCKET_NAME"] = "test-bucket"
      Dragonfly.app.stub(:datastore, s3_datastore_mock) do
        yield encoder_mock, api_mock
      end
    ensure
      ENV.delete("S3_BUCKET_NAME")
    end

    def perform_job(video, encoder_mock, api_mock)
      Folio::CraMediaCloud::Encoder.stub(:new, encoder_mock) do
        Folio::CraMediaCloud::Api.stub(:new, api_mock) do
          Folio::CraMediaCloud::CreateMediaJob.perform_now(video)
        end
      end
    end
end
