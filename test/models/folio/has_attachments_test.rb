# frozen_string_literal: true

require 'test_helper'

module Folio
  class HasAttachmentsTest < ActiveSupport::TestCase
    test 'with_cover scope' do
      with = create(:folio_node)
      without = create(:folio_node)

      with.cover = create(:folio_image)
      assert_equal([with], Folio::Node.with_cover)
    end

    test 'with_images scope' do
      with = create(:folio_node)
      without = create(:folio_node)

      image = create(:folio_image)
      with.images << image
      without.cover = image

      assert_equal([with], Folio::Node.with_images)
    end

    test 'with_documents scope' do
      with = create(:folio_node)
      without = create(:folio_node)

      with.documents << create(:folio_document)

      assert_equal([with], Folio::Node.with_documents)
    end
  end
end
