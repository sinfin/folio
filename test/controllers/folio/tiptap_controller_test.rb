# frozen_string_literal: true

require "test_helper"

class Folio::TiptapControllerTest < ActionDispatch::IntegrationTest
  setup do
    create_and_host_site
  end

  test "should get block_editor" do
    get folio.block_editor_tiptap_path
    assert_response :ok
  end

  test "should post block_editor" do
    post folio.block_editor_tiptap_path
    assert_response :ok
  end

  test "should get rich_text_editor" do
    get folio.rich_text_editor_tiptap_path
    assert_response :ok
  end

  test "should post rich_text_editor" do
    post folio.rich_text_editor_tiptap_path
    assert_response :ok
  end
end
