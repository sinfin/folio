# frozen_string_literal: true

require 'test_helper'

module Folio
  class GenerateThumbnailJobTest < ActiveJob::TestCase
    test 'geometry_from' do
      image = create(:folio_image)
      assert_equal 100, image.file_width
      assert_equal 100, image.file_height

      assert_equal('333x333#', GenerateThumbnailJob.new.send(:geometry_from, image, '333x333#'))
      assert_equal('333x333+10#', GenerateThumbnailJob.new.send(:geometry_from, image, '333x333#', x: 0.1))
      assert_equal('333x333+0+10#', GenerateThumbnailJob.new.send(:geometry_from, image, '333x333#', y: 0.1))
      assert_equal('333x333+10+10', GenerateThumbnailJob.new.send(:geometry_from, image, '333x333', x: 0.1, y: 0.1))
    end
  end
end
