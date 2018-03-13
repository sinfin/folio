# frozen_string_literal: true

require 'test_helper'

module Folio
  class ThumbnailsControllerTest < ActionDispatch::IntegrationTest
    def setup
      create(:folio_site)
    end

    test 'the truth' do
      image = create(:folio_image)
      get image.thumb('200x200').url
      assert_response(202)
    end
  end
end
