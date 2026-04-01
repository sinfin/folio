# frozen_string_literal: true

require "test_helper"

class Folio::S3::CreateFileJobTest < ActiveJob::TestCase
  class FakeRecord
    attr_accessor :slug, :save_calls

    def initialize(sequence)
      @sequence = sequence.dup
      @save_calls = 0
      @slug_errors = []
    end

    def save
      @save_calls += 1
      outcome = @sequence.shift || :ok

      case outcome
      when :ok
        true
      when :validation_conflict
        @slug_errors = ["has already been taken"]
        false
      when :db_conflict
        raise ActiveRecord::RecordNotUnique.new("duplicate key value violates unique constraint")
      when :other_error
        @slug_errors = []
        false
      else
        false
      end
    end

    def errors
      { slug: @slug_errors }
    end
  end

  test "video upload falls back to download flow for local file system" do
    # In test env with FileDataStore, video upload should use the standard download path
    # (S3 copy path is only for actual S3 storage)
    s3_path = "test_video.mp4"

    # Create a temp file simulating S3 uploaded file
    source_path = "#{Folio::S3::Client::LOCAL_TEST_PATH}/#{s3_path}"
    FileUtils.mkdir_p(File.dirname(source_path))
    fixture_path = Folio::Engine.root.join("test/fixtures/folio/blank.mp4").to_s
    FileUtils.cp(fixture_path, source_path)

    site = get_any_site

    Folio::S3::CreateFileJob.perform_now(
      s3_path: s3_path,
      type: "Folio::File::Video",
      attributes: { site_id: site.id }
    )

    # File should be created successfully via download path
    created_video = Folio::File::Video.last
    assert created_video.present?, "Video should be created"
    assert created_video.file_uid.present?, "Video should have file_uid"
    assert created_video.file_name.present?, "Video should have file_name"
  ensure
    FileUtils.rm_f(source_path) if source_path
  end

  test "video upload uses S3 server-side copy when on real S3 storage" do
    site = get_any_site
    s3_path = "uploads/test_video.mp4"

    fake_head = Struct.new(:content_length, :content_type).new(5_000_000, "video/mp4")
    copy_source_key = nil

    job = Folio::S3::CreateFileJob.new
    job.define_singleton_method(:use_local_file_system?) { false }

    # Stub before_validation :set_video_file_dimensions — it calls file_url_or_path which tries
    # to fetch the Dragonfly-generated UID from FileDataStore (no actual file exists there).
    # Provide fake dimensions so file_width/file_height validations pass.
    Folio::File::Video.define_method(:set_video_file_dimensions) do
      self.file_width = 1280
      self.file_height = 720
      self.file_track_duration = 0
    end

    job.stub(:test_aware_s3_exists?, true) do
      job.stub(:s3_copy_object, ->(source_key:, dest_key:) { copy_source_key = source_key }) do
        job.stub(:s3_head_object, fake_head) do
          job.stub(:test_aware_s3_delete, nil) do
            job.perform(s3_path: s3_path, type: "Folio::File::Video", attributes: { site_id: site.id })
          end
        end
      end
    end

    created_video = Folio::File::Video.last
    assert created_video.present?, "Video should be created"
    assert created_video.file_uid.present?, "Video should have a Dragonfly UID"
    assert_equal "test_video.mp4", created_video.file_name
    assert_equal 5_000_000, created_video.file_size
    assert_equal "video/mp4", created_video.file_mime_type
    assert_includes copy_source_key, s3_path, "s3_copy_object should have been called with the source path"
  ensure
    Folio::File::Video.remove_method(:set_video_file_dimensions)
  end

  test "save_file_with_slug_retry succeeds after validation slug conflict" do
    job = Folio::S3::CreateFileJob.new
    fake = FakeRecord.new([:validation_conflict, :ok])
    job.instance_variable_set(:@file, fake)

    assert job.send(:save_file_with_slug_retry)
    assert_equal 2, fake.save_calls
  end

  test "save_file_with_slug_retry succeeds after DB unique violation" do
    job = Folio::S3::CreateFileJob.new
    fake = FakeRecord.new([:db_conflict, :ok])
    job.instance_variable_set(:@file, fake)

    assert job.send(:save_file_with_slug_retry)
    assert_equal 2, fake.save_calls
  end

  test "save_file_with_slug_retry returns false on non-slug errors" do
    job = Folio::S3::CreateFileJob.new
    fake = FakeRecord.new([:other_error])
    job.instance_variable_set(:@file, fake)

    assert_not job.send(:save_file_with_slug_retry)
    assert_equal 1, fake.save_calls
  end
end
