# frozen_string_literal: true

require 'test_helper'
require_relative 'base_controller_test'

module Folio
  class Console::DocumentsControllerTest < Console::BaseControllerTest
    test 'index' do
      get console_documents_url
      assert_response :success
    end

    test 'edit' do
      document = create(:folio_document)
      get edit_console_document_url(document)
      assert_response :success
    end

    test 'create' do
      assert_equal(0, Document.count)
      post console_documents_url, params: {
        file: {
          file: fixture_file_upload('test/fixtures/folio/test.gif'),
          type: 'Folio::Document',
        }
      }
      assert_response :success
      assert_equal(1, Document.count)
    end

    test 'update' do
      document = create(:folio_document)
      put console_document_url(document), params: {
        file: {
          tag_list: 'foo'
        }
      }
      assert_redirected_to console_documents_path
      assert_equal(['foo'], document.reload.tag_list)
    end

    test 'destroy' do
      document = create(:folio_document)
      assert_equal(1, Document.count)
      delete console_document_url(document)
      assert_equal(0, Document.count)
    end
  end
end
