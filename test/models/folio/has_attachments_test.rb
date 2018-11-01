# frozen_string_literal: true

require 'test_helper'

module Folio
  class HasAttachmentsTest < ActiveSupport::TestCase
    test 'with_cover scope' do
      with = create(:folio_node)
      without = create(:folio_node)

      with.cover = create(:folio_image)
      assert_equal([with], Node.with_cover)
    end

    test 'with_images scope' do
      with = create(:folio_node)
      without = create(:folio_node)

      image = create(:folio_image)
      with.images << image
      without.cover = image

      assert_equal([with], Node.with_images)
    end

    test 'with_documents scope' do
      with = create(:folio_node)
      without = create(:folio_node)

      with.documents << create(:folio_document)

      assert_equal([with], Node.with_documents)
    end

    test 'has_one_document_placement' do
      class MyPlacement < FilePlacement
      end

      class MyNode < Node
        include HasAttachments
        has_one_document_placement :my_file, placement: 'MyPlacement'
      end

      assert_equal(0, MyPlacement.count)
      document = create(:folio_document)

      my_node = MyNode.create!(title: 'MyNode',
                               my_placement_attributes: { file: document })

      assert_equal(1, MyPlacement.count)
      assert_equal(document, my_node.my_file)
    end
  end
end
