# frozen_string_literal: true

require 'test_helper'

class Folio::DownloadsControllerTest < ActionDispatch::IntegrationTest
  include Folio::Engine.routes.url_helpers

  test 'show' do
    create(:folio_site)
    doc = create(:folio_document)
    get download_path(doc, doc.file_name, locale: :cs)
    assert_redirected_to doc.file.remote_url
  end
end
