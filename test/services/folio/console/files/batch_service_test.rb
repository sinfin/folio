# frozen_string_literal: true

require "test_helper"

class Folio::Console::Files::BatchServiceTest < ActiveSupport::TestCase
  test "tracks and clears upload-added file sources" do
    service = Folio::Console::Files::BatchService.new(
      session_id: SecureRandom.hex(8),
      file_class_name: "Folio::File::Image"
    )

    service.add_file(1, source: Folio::Console::Files::BatchService::SOURCE_UPLOAD)
    service.add_file(2)

    assert_equal [1], service.upload_added_file_ids
    assert service.upload_added_file?(1)
    assert_not service.upload_added_file?(2)

    service.remove_files([1])

    assert_empty service.upload_added_file_ids
    assert_equal [2], service.get_file_ids

    service.clear_files

    assert_empty service.get_file_ids
    assert_empty service.file_sources
  end
end
