# frozen_string_literal: true

require "test_helper"

class Folio::Mcp::Tools::VersionToolsTest < ActiveSupport::TestCase
  class AuditedTestPage < Folio::Page
    include Folio::Audited::Model
    audited console: true
  end

  setup do
    @site = get_any_site
    @user = create(:folio_user, :superadmin, auth_site: @site)

    # Configure MCP with versioned resource
    Folio::Mcp.reset_configuration!
    Folio::Mcp.configure do |config|
      config.enabled = true
      config.resources = {
        pages: {
          model: "Folio::Mcp::Tools::VersionToolsTest::AuditedTestPage",
          fields: %i[title slug meta_title meta_description published locale],
          allowed_actions: %i[read create update],
          versioned: true,
          authorize_with: :console_ability
        }
      }
    end

    @server_context = {
      user: @user,
      site: @site,
      audit_logger: nil
    }
  end

  teardown do
    Folio::Mcp.reset_configuration!
  end

  # Helper to check if response is error
  def response_error?(result)
    # MCP::Tool::Response has .error? method
    result.error?
  end

  # Helper to get response content
  def response_content(result)
    # MCP::Tool::Response has .content method returning array of content blocks
    JSON.parse(result.content.first[:text])
  end

  test "list_record_versions returns error for non-versioned resource" do
    Folio::Mcp.configure do |config|
      config.enabled = true
      config.resources = {
        pages: {
          model: "Folio::Page",
          fields: %i[title],
          allowed_actions: %i[read],
          versioned: false
        }
      }
    end

    page = create(:folio_page, site: @site)

    result = Folio::Mcp::Tools::ListRecordVersions.call(
      resource_name: :pages,
      id: page.id,
      server_context: @server_context
    )

    assert response_error?(result)
    parsed = response_content(result)
    assert_match(/versioning not enabled/i, parsed["error"])
  end

  test "list_record_versions returns versions for audited record" do
    Audited.stub(:auditing_enabled, true) do
      page = AuditedTestPage.create!(
        title: "Version 1",
        site: @site,
        locale: "cs"
      )

      page.update!(title: "Version 2")
      page.update!(title: "Version 3")

      result = Folio::Mcp::Tools::ListRecordVersions.call(
        resource_name: :pages,
        id: page.id,
        server_context: @server_context
      )

      assert_not response_error?(result)
      parsed = response_content(result)

      assert_equal page.id, parsed["record_id"]
      assert_equal 3, parsed["total_count"]
      assert_equal 3, parsed["versions"].size

      # Versions should be in descending order
      assert_equal 3, parsed["versions"][0]["version"]
      assert_equal 2, parsed["versions"][1]["version"]
      assert_equal 1, parsed["versions"][2]["version"]

      # Each version should have expected fields
      version = parsed["versions"][0]
      assert version["created_at"].present?
      assert_includes %w[create update], version["action"]
      assert version.key?("preview_url")
      assert version.key?("changes")
    end
  end

  test "list_record_versions respects pagination" do
    Audited.stub(:auditing_enabled, true) do
      page = AuditedTestPage.create!(title: "V1", site: @site, locale: "cs")
      5.times { |i| page.update!(title: "V#{i + 2}") }

      # Get first 3
      result = Folio::Mcp::Tools::ListRecordVersions.call(
        resource_name: :pages,
        id: page.id,
        limit: 3,
        offset: 0,
        server_context: @server_context
      )

      parsed = response_content(result)
      assert_equal 3, parsed["versions"].size
      assert_equal 6, parsed["total_count"]
      assert_equal 6, parsed["versions"][0]["version"]

      # Get next 3
      result = Folio::Mcp::Tools::ListRecordVersions.call(
        resource_name: :pages,
        id: page.id,
        limit: 3,
        offset: 3,
        server_context: @server_context
      )

      parsed = response_content(result)
      assert_equal 3, parsed["versions"].size
      assert_equal 3, parsed["versions"][0]["version"]
    end
  end

  test "list_record_versions returns error for non-existent record" do
    result = Folio::Mcp::Tools::ListRecordVersions.call(
      resource_name: :pages,
      id: 999999,
      server_context: @server_context
    )

    assert response_error?(result)
    parsed = response_content(result)
    assert_match(/not found/i, parsed["error"])
  end

  test "get_record_version returns specific version" do
    Audited.stub(:auditing_enabled, true) do
      page = AuditedTestPage.create!(
        title: "Original Title",
        meta_description: "Original description",
        site: @site,
        locale: "cs"
      )

      page.update!(title: "Updated Title", meta_description: "Updated description")

      # Get version 1
      result = Folio::Mcp::Tools::GetRecordVersion.call(
        resource_name: :pages,
        id: page.id,
        version: 1,
        server_context: @server_context
      )

      assert_not response_error?(result)
      parsed = response_content(result)

      assert_equal 1, parsed["version_info"]["version"]
      assert_equal "create", parsed["version_info"]["action"]
      assert parsed["version_info"]["preview_url"].present?
      assert parsed["version_info"]["restorable"]

      assert_equal "Original Title", parsed["record"]["title"]
      assert_equal "Original description", parsed["record"]["meta_description"]
    end
  end

  test "get_record_version returns error for non-existent version" do
    Audited.stub(:auditing_enabled, true) do
      page = AuditedTestPage.create!(title: "Test", site: @site, locale: "cs")

      result = Folio::Mcp::Tools::GetRecordVersion.call(
        resource_name: :pages,
        id: page.id,
        version: 999,
        server_context: @server_context
      )

      assert response_error?(result)
      parsed = response_content(result)
      assert_match(/version.*not found/i, parsed["error"])
    end
  end

  test "restore_record_version restores to previous version" do
    Audited.stub(:auditing_enabled, true) do
      page = AuditedTestPage.create!(
        title: "Original",
        meta_description: "Original desc",
        site: @site,
        locale: "cs"
      )

      page.update!(title: "Changed", meta_description: "Changed desc")

      assert_equal "Changed", page.reload.title
      assert_equal 2, page.audits.count

      # Restore to version 1
      result = Folio::Mcp::Tools::RestoreRecordVersion.call(
        resource_name: :pages,
        id: page.id,
        version: 1,
        server_context: @server_context
      )

      assert_not response_error?(result)
      parsed = response_content(result)

      assert_match(/successfully restored/i, parsed["message"])
      assert_equal 1, parsed["restored_from_version"]
      assert_equal 3, parsed["new_version"]

      # Verify the record was restored
      page.reload
      assert_equal "Original", page.title
      assert_equal "Original desc", page.meta_description
      assert_equal 3, page.audits.count
    end
  end

  test "restore_record_version requires update permission" do
    Folio::Mcp.configure do |config|
      config.enabled = true
      config.resources = {
        pages: {
          model: "Folio::Mcp::Tools::VersionToolsTest::AuditedTestPage",
          fields: %i[title],
          allowed_actions: %i[read], # no update!
          versioned: true
        }
      }
    end

    Audited.stub(:auditing_enabled, true) do
      page = AuditedTestPage.create!(title: "Test", site: @site, locale: "cs")
      page.update!(title: "Changed")

      result = Folio::Mcp::Tools::RestoreRecordVersion.call(
        resource_name: :pages,
        id: page.id,
        version: 1,
        server_context: @server_context
      )

      assert response_error?(result)
      parsed = response_content(result)
      assert_match(/update action not allowed/i, parsed["error"])
    end
  end

  test "authorization error returns proper error response" do
    # Create a non-superadmin user without console access
    limited_user = create(:folio_user, auth_site: @site)
    limited_context = @server_context.merge(user: limited_user)

    Audited.stub(:auditing_enabled, true) do
      page = AuditedTestPage.create!(title: "Test", site: @site, locale: "cs")

      result = Folio::Mcp::Tools::ListRecordVersions.call(
        resource_name: :pages,
        id: page.id,
        server_context: limited_context
      )

      assert response_error?(result)
      parsed = response_content(result)
      assert_match(/not authorized/i, parsed["error"])
    end
  end

  test "preview_url contains correct path" do
    Audited.stub(:auditing_enabled, true) do
      page = AuditedTestPage.create!(title: "Test", site: @site, locale: "cs")

      result = Folio::Mcp::Tools::ListRecordVersions.call(
        resource_name: :pages,
        id: page.id,
        server_context: @server_context
      )

      parsed = response_content(result)
      preview_url = parsed["versions"][0]["preview_url"]

      assert preview_url.present?
      assert_match %r{/folio/console/pages/#{page.id}/revision/1}, preview_url
    end
  end

  test "changes summary includes modified fields" do
    Audited.stub(:auditing_enabled, true) do
      page = AuditedTestPage.create!(title: "Original", site: @site, locale: "cs")
      page.update!(title: "Changed", meta_title: "New SEO")

      result = Folio::Mcp::Tools::ListRecordVersions.call(
        resource_name: :pages,
        id: page.id,
        server_context: @server_context
      )

      parsed = response_content(result)
      # Version 2 should show title and meta_title in changes
      update_version = parsed["versions"].find { |v| v["version"] == 2 }
      assert update_version["changes"].include?("title")
      assert update_version["changes"].include?("meta_title")
    end
  end
end
