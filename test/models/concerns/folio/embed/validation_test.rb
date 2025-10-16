# frozen_string_literal: true

require "test_helper"

class Folio::Embed::ValidationTest < ActiveSupport::TestCase
  def setup
    @node = Dummy::Tiptap::Node::Embed.new
  end

  test "validation passes with valid embed data containing html" do
    @node.folio_embed_data = {
      "active" => true,
      "html" => "<iframe>...</iframe>"
    }

    assert @node.valid?
    assert_empty @node.errors[:folio_embed_data]
  end

  test "validation passes with valid embed data containing type and url" do
    @node.folio_embed_data = {
      "active" => true,
      "type" => "youtube",
      "url" => "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
    }

    assert @node.valid?
    assert_empty @node.errors[:folio_embed_data]
  end

  test "validation fails when folio_embed_data is blank" do
    @node.folio_embed_data = nil
    assert_not @node.valid?
    assert_includes @node.errors.details[:folio_embed_data].map { |e| e[:error] }, :blank

    @node.folio_embed_data = {}
    assert_not @node.valid?
    assert_includes @node.errors.details[:folio_embed_data].map { |e| e[:error] }, :blank
  end

  test "validation fails when active is false" do
    @node.folio_embed_data = {
      "active" => false,
      "type" => "youtube",
      "url" => "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
    }

    assert_not @node.valid?
    assert_includes @node.errors.details[:folio_embed_data].map { |e| e[:error] }, :blank
  end

  test "validation fails when folio_embed_data is not a hash" do
    @node.folio_embed_data = "not a hash"
    assert_nil @node.folio_embed_data

    assert_not @node.valid?
    assert_includes @node.errors.details[:folio_embed_data].map { |e| e[:error] }, :blank
  end

  test "validation fails with invalid URL for youtube type" do
    @node.folio_embed_data = {
      "active" => true,
      "type" => "youtube",
      "url" => "https://example.com/not-youtube"
    }

    assert_not @node.valid?
    assert_includes @node.errors.details[:folio_embed_data].map { |e| e[:error] }, :invalid
  end

  test "validation passes with valid URLs for supported types" do
    valid_combinations = [
      { "type" => "youtube", "url" => "https://www.youtube.com/watch?v=dQw4w9WgXcQ" },
      { "type" => "youtube", "url" => "https://youtu.be/dQw4w9WgXcQ" },
      { "type" => "instagram", "url" => "https://www.instagram.com/p/ABC123/" },
      { "type" => "pinterest", "url" => "https://www.pinterest.com/pin/123456789/" },
      { "type" => "twitter", "url" => "https://twitter.com/user/status/123" },
      { "type" => "twitter", "url" => "https://x.com/user/status/123" }
    ]

    valid_combinations.each do |combo|
      @node.folio_embed_data = {
        "active" => true,
        **combo
      }

      assert @node.valid?, "Should be valid with #{combo.inspect}"
      assert_empty @node.errors[:folio_embed_data]
    end
  end

  test "validation fails when embed data has no html and no valid type/url combination" do
    @node.folio_embed_data = {
      "active" => true,
      "type" => "unknown_type",
      "url" => "https://example.com"
    }

    assert_not @node.valid?
    assert_includes @node.errors.details[:folio_embed_data].map { |e| e[:error] }, :blank
  end
end
