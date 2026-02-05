# frozen_string_literal: true

require "test_helper"

class Folio::Console::Api::TiptapRevisionsControllerTest < Folio::Console::BaseControllerTest
  attr_reader :site, :page, :another_user

  def setup
    super
    @site = create_site
    @page = create(:folio_page, site: @site)
    @another_user = create(:folio_user, :superadmin)
  end

  test "save_revision - creates new revision" do
    content = { content: "Test revision content" }

    assert_difference "Folio::Tiptap::Revision.count", 1 do
      post save_revision_console_api_tiptap_revisions_path(format: :json), params: {
        placement: { type: "Folio::Page", id: @page.id },
        tiptap_revision: { content: }
      }
    end

    assert_response :ok

    response_data = response.parsed_body
    assert response_data["success"]
    assert response_data["revision_id"]
    assert response_data["created_at"]
    assert response_data["updated_at"]

    revision = Folio::Tiptap::Revision.find(response_data["revision_id"])
    assert_equal @page, revision.placement
    assert_equal @superadmin, revision.user
    assert_equal content.stringify_keys, revision.content
  end

  test "save_revision - updates existing revision" do
    content = { content: "Initial content" }
    revision = @page.tiptap_revisions.create!(user: @superadmin, content:)

    updated_content = { content: "Updated content" }

    assert_no_difference "Folio::Tiptap::Revision.count" do
      post save_revision_console_api_tiptap_revisions_path(format: :json), params: {
        placement: { type: "Folio::Page", id: @page.id },
        tiptap_revision: { content: updated_content }
      }
    end

    assert_response :ok

    revision.reload
    assert_equal updated_content.stringify_keys, revision.content
  end

  test "delete_revision - deletes existing revision" do
    @page.tiptap_revisions.create!(user: @superadmin, content: { content: "To delete" })

    assert_difference "Folio::Tiptap::Revision.count", -1 do
      delete delete_revision_console_api_tiptap_revisions_path(format: :json), params: {
        placement: { type: "Folio::Page", id: @page.id }
      }
    end

    assert_response :ok
    assert response.parsed_body["success"]
  end

  test "delete_revision - returns not found when no revision exists" do
    assert_no_difference "Folio::Tiptap::Revision.count" do
      delete delete_revision_console_api_tiptap_revisions_path(format: :json), params: {
        placement: { type: "Folio::Page", id: @page.id }
      }
    end

    assert_response :not_found
    assert_equal false, response.parsed_body["success"]
  end

  test "takeover_revision - takes over another user's revision (creating mine if needed)" do
    from_content = { content: "Another user's content" }
    from_revision = @page.tiptap_revisions.create!(user: @another_user, content: from_content)

    assert_difference "Folio::Tiptap::Revision.count", 1 do
      post takeover_revision_console_api_tiptap_revisions_path(format: :json), params: {
        from_user_id: @another_user.id,
        placement: { type: "Folio::Page", id: @page.id }
      }
    end

    assert_response :ok
    assert response.parsed_body["success"]

    my_revision = @page.tiptap_revisions.find_by(user: @superadmin)
    assert_not_nil my_revision
    assert_equal from_content.stringify_keys, my_revision.content

    @another_user.reload
    assert_nil @another_user.console_url

    from_content2 = { content: "Another user's content 2" }
    from_revision.update!(content: from_content2)

    assert_no_difference "Folio::Tiptap::Revision.count" do
      post takeover_revision_console_api_tiptap_revisions_path(format: :json), params: {
        from_user_id: @another_user.id,
        placement: { type: "Folio::Page", id: @page.id }
      }
    end

    my_revision.reload
    assert_equal from_content2.stringify_keys, my_revision.content
  end

  test "takeover_revision - returns error when no revision found" do
    post takeover_revision_console_api_tiptap_revisions_path(format: :json), params: {
      from_user_id: @another_user.id,
      placement: { type: "Folio::Page", id: @page.id }
    }

    assert_response :not_found
    assert response.parsed_body["error"]
    assert_includes response.parsed_body["error"], "rozpracovaná verze"
  end

  test "find_placement - works with different placement types" do
    # Test would need a different model that includes Folio::Tiptap::Model
    # For now just test that Page works
    content = { content: "Test content" }

    post save_revision_console_api_tiptap_revisions_path(format: :json), params: {
      placement: { type: "Folio::Page", id: @page.id },
      tiptap_revision: { content: content }
    }

    assert_response :ok
  end

  test "find_placement - returns 404 for non-existent placement" do
    non_existent_id = Folio::Page.maximum(:id).to_i + 1000

    post save_revision_console_api_tiptap_revisions_path(format: :json), params: {
      placement: { type: "Folio::Page", id: non_existent_id },
      tiptap_revision: { content: { content: "Test" } }
    }

    assert_response :not_found
  end
end
