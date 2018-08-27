# frozen_string_literal: true

require 'test_helper'

module Folio
  class PublishableTest < ActiveSupport::TestCase
    test 'nillifies blanks' do
      node = create(:folio_node, title: 'foo', perex: '', content: '')
      assert_nil(node.perex)
      assert_nil(node.content)
    end
  end
end
