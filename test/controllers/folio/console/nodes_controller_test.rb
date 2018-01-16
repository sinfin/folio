# frozen_string_literal: true

require 'test_helper'
require_relative 'base_controller_test'

module Folio
  class Console::NodesControllerTest < Console::BaseControllerTest
    include Engine.routes.url_helpers

    setup do
      @node = create(:folio_node)
    end

    test 'should get index' do
      get console_nodes_url
      assert_response :success
    end

    test 'should get new' do
      get new_console_node_url
      assert_response :success
    end

    test 'should get edit' do
      get edit_console_node_url(@node)
      assert_response :success
    end
  end
end
