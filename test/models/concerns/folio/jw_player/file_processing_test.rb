# frozen_string_literal: true

require "test_helper"

class Folio::JwPlayer::FileProcessingTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  attr_reader :tv_file

  class TestMediaFile < Folio::File::Video
    include Folio::JwPlayer::FileProcessing
  end

  def setup
    super
    @tv_file = TestMediaFile.new(site: get_any_site)
    @tv_file.file = Folio::Engine.root.join("test/fixtures/folio/test_7secs.mp4")

    assert tv_file.unprocessed?
    # to stop callback processing chain, we stub call to `create_full_media`
    expect_method_called_on(object: tv_file, method: :create_full_media) do
      tv_file.save!
    end
    assert tv_file.processing?
  end

  test "#create_full_media" do
    assert_enqueued_jobs 1, only: Folio::JwPlayer::CreateFullMediaJob do
      tv_file.create_full_media
    end

    assert tv_file.processing?, "AASM state #{tv_file.aasm_state}"
    assert_equal "enqueued", tv_file.processing_state, tv_file.remote_services_data
    assert_equal "jw_player", tv_file.processing_service
  end

  # called from preriodic check job or webhook
  test "#full_media_processed!" do
    tv_file.remote_services_data = {
      "service" => "jw_player",
      "processing_state" => "full_media_processing", # set by Folio::JwPlayer::CreateFullMediaJob
      "remote_key" => "bflmpsvz" # set by Folio::JwPlayer::CreateFullMediaJob
    }

    assert_not tv_file.full_media_processed?

    expect_method_called_on(object: tv_file, method: :create_preview_media) do
      tv_file.full_media_processed!
    end

    assert tv_file.full_media_processed?
    assert tv_file.processing?
  end

  test "#create_preview_media" do
    tv_file.remote_services_data = {
      "service" => "jw_player",
      "processing_state" => "full_media_processed", # set by `full_media_processed` method
      "remote_key" => "bflmpsvz" # set by Folio::JwPlayer::CreateFullMediaJob
    }

    assert_enqueued_jobs 1, only: Folio::JwPlayer::CreatePreviewMediaJob do
      tv_file.create_preview_media
    end

    assert tv_file.processing?
    assert tv_file.full_media_processed?
  end

  # called from preriodic check job or webhook
  test "#preview_media_processed!" do
    tv_file.remote_services_data = {
      "service" => "jw_player",
      "processing_state" => "preview_media_processing", # set by Folio::JwPlayer::CreatePreviewMediaJob
      "remote_key" => "bflmpsvz", # set by Folio::JwPlayer::CreateFullMediaJob
      "remote_preview_key" => "hchkrdtn" # set by Folio::JwPlayer::CreatePreviewMediaJob
    }

    assert tv_file.full_media_processed?
    assert_not tv_file.preview_media_processed?
    assert tv_file.processing?

    expect_method_called_on(object: tv_file, method: :processing_done!) do
      tv_file.preview_media_processed!
    end

    assert tv_file.preview_media_processed?
  end

  test "deletes remote media on destroy" do
    tv_file.remote_services_data = {
      "service" => "jw_player",
      "processing_state" => "preview_media_processing", # set by Folio::JwPlayer::CreatePreviewMediaJob
      "remote_key" => "bflmpsvz", # set by Folio::JwPlayer::CreateFullMediaJob
      "remote_preview_key" => "hchkrdtn" # set by Folio::JwPlayer::CreatePreviewMediaJob
    }

    assert_enqueued_jobs 2, only: Folio::JwPlayer::DeleteMediaJob  do
      tv_file.destroy
    end
  end

  test "sets preview periode on change of duration" do
    assert_equal(["processing_step_started_at"], tv_file.remote_services_data.keys)
    assert_equal 7, tv_file.preview_duration_in_seconds
    assert_equal 7, tv_file.preview_duration

    tv_file.preview_duration = 4

    assert_equal 4, tv_file.preview_duration_in_seconds
    assert_equal 4, tv_file.preview_duration
    assert_equal({ "start_at" => 0, "end_at" => 4 }, tv_file.remote_services_data["preview_interval"])

    tv_file.preview_duration = 1000
    # file have 7 secs not 1000
    assert_equal 7, tv_file.preview_duration_in_seconds
    assert_equal 7, tv_file.preview_duration
    assert_equal({ "start_at" => 0, "end_at" => 7 }, tv_file.remote_services_data["preview_interval"])
  end
end
