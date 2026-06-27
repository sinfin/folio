# frozen_string_literal: true

require "test_helper"

class Folio::Tiptap::FormLayoutBuilderTest < ActiveSupport::TestCase
  Node = Class.new(Folio::Tiptap::Node)
  STRUCTURE = {
    title: { type: :string },
    cover: {
      type: :folio_attachment,
      attachment_key: :cover,
      placement_key: :cover_placement,
      file_type: "Folio::File::Image",
      has_many: false,
    },
    body: { type: :text },
  }

  test "accepts supported built in layouts" do
    assert_nil build(nil)
    assert_equal :aside_attachments, build(:aside_attachments)
  end

  test "accepts rows and columns with direct field names" do
    assert_equal({
      rows: [
        :title,
        {
          columns: [
            :cover,
            { rows: [:body] },
          ],
        },
      ],
    }, build({
      rows: [
        "title",
        {
          columns: [
            :cover,
            { rows: [:body] },
          ],
        },
      ],
    }))
  end

  test "accepts string rows and columns keys" do
    assert_equal({
      rows: [
        {
          columns: [
            :title,
            :cover,
          ],
        },
        :body,
      ],
    }, build({
      "rows" => [
        {
          "columns" => [
            "title",
            "cover",
          ],
        },
        "body",
      ],
    }))
  end

  test "rejects unsupported form_layout values" do
    error = assert_raises(ArgumentError) { build(:unknown) }

    assert_match(/Expected form_layout to be nil, :aside_attachments, or a Hash/, error.message)
  end

  test "rejects unsupported form_layout items" do
    error = assert_raises(ArgumentError) do
      build({
        columns: [
          :title,
          1,
        ],
      })
    end

    assert_match(/Expected form_layout item to be a field, rows hash, or columns hash/, error.message)
  end

  test "rejects unknown fields" do
    error = assert_raises(ArgumentError) do
      build({
        columns: [
          :title,
          :cover,
          :missing,
        ],
      })
    end

    assert_match(/Unknown field `missing`/, error.message)
  end

  test "rejects duplicate fields" do
    error = assert_raises(ArgumentError) do
      build({
        columns: [
          :title,
          :cover,
          :body,
          :title,
        ],
      })
    end

    assert_match(/Duplicate fields in form_layout: title/, error.message)
  end

  test "rejects missing fields" do
    error = assert_raises(ArgumentError) do
      build({
        columns: [
          :title,
          :cover,
        ],
      })
    end

    assert_match(/Missing fields in form_layout: body/, error.message)
  end

  test "rejects ambiguous row and column hashes" do
    error = assert_raises(ArgumentError) do
      build({
        rows: [:title],
        columns: [:title],
      })
    end

    assert_match(/either :rows or :columns/, error.message)
  end

  test "rejects empty rows and columns" do
    error = assert_raises(ArgumentError) do
      build({
        rows: [],
      })
    end

    assert_match(/rows to be a non-empty Array/, error.message)
  end

  private
    def build(form_layout)
      Folio::Tiptap::FormLayoutBuilder.call(klass: Node,
                                            structure: STRUCTURE,
                                            form_layout:)
    end
end
