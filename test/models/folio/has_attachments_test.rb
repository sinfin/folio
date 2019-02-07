# frozen_string_literal: true

require 'test_helper'

class Folio::HasAttachmentsTest < ActiveSupport::TestCase
  test 'has_one_document_placement' do
    class MyFilePlacement < Folio::FilePlacement::Base
      folio_document_placement :my_file_placement
    end

    class MyNode < Folio::Page
      has_one_placement :my_file,
                        placement: 'Folio::HasAttachmentsTest::MyFilePlacement'
    end

    assert_equal(0, MyFilePlacement.count)
    document = create(:folio_document)

    my_node = MyNode.create!(title: 'MyNode',
                             my_file_placement_attributes: { file: document })

    assert_equal(1, MyFilePlacement.count)
    assert_equal(document, my_node.my_file)
  end
end
