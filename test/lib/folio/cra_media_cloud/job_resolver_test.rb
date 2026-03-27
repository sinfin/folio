# frozen_string_literal: true

require "test_helper"

class Folio::CraMediaCloud::JobResolverTest < ActiveSupport::TestCase
  def make_job(id:, ref_id:, status:, profile_group: "VoD", last_modified: "2026-01-01T00:00:00Z")
    {
      "id" => id,
      "refId" => ref_id,
      "status" => status,
      "profileGroup" => profile_group,
      "lastModified" => last_modified,
      "messages" => [],
      "output" => [],
    }
  end

  test "returns latest job by lastModified" do
    jobs = [
      make_job(id: 1, ref_id: "abc-123", status: "FAILED", last_modified: "2026-01-01T00:00:00Z"),
      make_job(id: 2, ref_id: "abc-123", status: "DONE", last_modified: "2026-01-02T00:00:00Z"),
    ]
    result = Folio::CraMediaCloud::JobResolver.resolve(jobs)
    assert_equal :done, result[:status]
    assert_equal 2, result[:job]["id"]
  end

  test "returns :not_found for empty jobs" do
    result = Folio::CraMediaCloud::JobResolver.resolve([])
    assert_equal :not_found, result[:status]
    assert_nil result[:job]
  end

  test "maps CRA statuses correctly" do
    { "PROCESSING" => :processing, "CREATED" => :processing,
      "DONE" => :done, "FAILED" => :failed, "ERROR" => :failed,
      "REMOVED" => :not_found }.each do |cra_status, expected|
      jobs = [make_job(id: 1, ref_id: "x", status: cra_status)]
      result = Folio::CraMediaCloud::JobResolver.resolve(jobs)
      assert_equal expected, result[:status], "Expected #{expected} for CRA status #{cra_status}"
    end
  end
end
