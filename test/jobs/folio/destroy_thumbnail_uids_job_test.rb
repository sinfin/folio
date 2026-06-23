# frozen_string_literal: true

require "test_helper"

class Folio::DestroyThumbnailUidsJobTest < ActiveJob::TestCase
  test "destroys each unique uid via Dragonfly datastore" do
    datastore = Minitest::Mock.new
    datastore.expect(:destroy, nil, ["uid-a"])
    datastore.expect(:destroy, nil, ["uid-b"])
    Dragonfly.app.stub(:datastore, datastore) do
      Folio::DestroyThumbnailUidsJob.perform_now(%w[uid-a uid-b uid-a])
    end
    datastore.verify
  end
end
