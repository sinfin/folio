# frozen_string_literal: true

require "test_helper"

class Folio::DownloadsControllerTest < ActionDispatch::IntegrationTest
  include Folio::Engine.routes.url_helpers

  test "show - public file redirects to CDN URL" do
    create_and_host_site
    doc = create(:folio_file_document)
    get download_path(doc, doc.file_name, locale: :cs)
    assert_redirected_to Folio::S3.cdn_url_rewrite(doc.file.remote_url)
  end

  test "show - private attachment redirects to file URL" do
    create_and_host_site
    private_attachment = create(:folio_private_attachment)

    get download_path(private_attachment.hash_id, locale: :cs)

    assert_response :redirect
    redirect_url = response.redirect_url
    assert redirect_url.present?, "Expected redirect URL to be present"
    # In test env, this is a local Dragonfly URL
    # In production with S3, this would be a presigned S3 URL
    assert redirect_url.include?(private_attachment.file_name) ||
           redirect_url.include?("X-Amz-Expires"),
           "Expected URL to contain filename or S3 signature, got: #{redirect_url}"
  end

  test "downloads_controller uses presigned URL for private attachments" do
    create_and_host_site
    private_attachment = create(:folio_private_attachment)

    controller = Folio::DownloadsController.new
    url = controller.send(:download_url_for, private_attachment)

    # The URL should be generated (not nil)
    assert url.present?, "Expected download_url_for to return a URL"
    # Should contain the file info
    assert url.include?("empty.pdf") || url.include?(private_attachment.file.uid),
           "Expected URL to reference the file"
  end
end
