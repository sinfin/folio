# frozen_string_literal: true

require 'test_helper'

class HomeControllerTest < ActionDispatch::IntegrationTest
  setup do
    create(:folio_site)
  end

  test 'get index' do
    get '/'
    assert_response :ok
  end
end
