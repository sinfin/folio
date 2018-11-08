# frozen_string_literal: true

require 'test_helper'

module Folio
  class HasAttachmentsTest < ActiveSupport::TestCase
    test 'has_one_document_placement' do
      class MyPlacement < FilePlacement::Base
        belongs_to :file, class_name: 'Folio::Document'
        belongs_to :placement,
                   polymorphic: true,
                   inverse_of: :my_placement,
                   required: true,
                   touch: true
      end

      class MyNode < Node
        include HasAttachments
        has_one_placement :my_file,
                          :my_placement,
                          class_name: 'Folio::Document',
                          placement: 'MyPlacement'
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
