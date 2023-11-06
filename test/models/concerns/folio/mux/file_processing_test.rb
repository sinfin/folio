# frozen_string_literal: true

require "test_helper"

class Folio::Mux::FileProcessingTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  attr_reader :tv_file

  class TestMediaFile < Folio::File::Audio
    include Folio::Mux::FileProcessing
  end

  setup do
    @tv_file = TestMediaFile.new(site: get_any_site)
    @tv_file.file = Folio::Engine.root.join("test/fixtures/folio/test_7secs.mp3")

    assert tv_file.unprocessed?
    # to stop callback processing chain, we stub call to `create_full_media`
    expect_method_called_on(object: tv_file, method: :create_full_media) do
      tv_file.save!
    end
    assert tv_file.processing?
  end

  test "#create_full_media" do
    assert_enqueued_jobs 1, only: Folio::Mux::CreateFullMediaJob do
      tv_file.create_full_media
    end

    assert tv_file.processing?, "AASM state #{tv_file.aasm_state}"
    assert_equal "enqueued", tv_file.processing_state, tv_file.remote_services_data
    assert_equal "mux", tv_file.processing_service
  end

  # called from preriodic check job or webhook
  test "#full_media_processed!" do
    tv_file.remote_services_data = {
      "service" => "mux",
      "processing_state" => "full_media_processing", # set by Folio::Mux::CreateFullMediaJob
      "remote_key" => "bflmpsvz" # set by Folio::Mux::CreateFullMediaJob
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
      "service" => "mux",
      "processing_state" => "full_media_processed", # set by `full_media_processed` method
      "remote_key" => "bflmpsvz" # set by Folio::Mux::CreateFullMediaJob
    }

    assert_enqueued_jobs 1, only: Folio::Mux::CreatePreviewMediaJob do
      tv_file.create_preview_media
    end

    assert tv_file.processing?
    assert tv_file.full_media_processed?
  end

  # called from preriodic check job or webhook
  test "#preview_media_processed!" do
    tv_file.remote_services_data = {
      "service" => "mux",
      "processing_state" => "preview_media_processing", # set by Folio::Mux::CreatePreviewMediaJob
      "remote_key" => "bflmpsvz", # set by Folio::Mux::CreateFullMediaJob
      "remote_preview_key" => "hchkrdtn" # set by Folio::Mux::CreatePreviewMediaJob
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
      "service" => "mux",
      "processing_state" => "preview_media_processing", # set by Folio::Mux::CreatePreviewMediaJob
      "remote_key" => "bflmpsvz", # set by Folio::Mux::CreateFullMediaJob
      "remote_preview_key" => "hchkrdtn" # set by Folio::Mux::CreatePreviewMediaJob
    }

    assert_enqueued_jobs 2, only: Folio::Mux::DeleteMediaJob  do
      tv_file.destroy
    end
  end

  test "updates preview media on file.preview_duration change" do
    tv_file.remote_services_data = {
      "service" => "mux",
      "processing_state" => "preview_media_processing", # set by Folio::Mux::CreatePreviewMediaJob
      "remote_key" => "bflmpsvz", # set by Folio::Mux::CreateFullMediaJob
      "remote_preview_key" => "hchkrdtn" # set by Folio::Mux::CreatePreviewMediaJob
    }
    tv_file.save!
    assert_equal 7, tv_file.file_track_duration_in_seconds
    assert_equal 7, tv_file.preview_duration_in_seconds
    assert tv_file.processing?

    tv_file.processing_done!

    assert_enqueued_jobs 1, only: Folio::Mux::CreatePreviewMediaJob do # will enqueue delete job for previous preview
      tv_file.preview_duration = 5
      tv_file.save!
    end
  end
end
