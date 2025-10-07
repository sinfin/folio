# frozen_string_literal: true

require "test_helper"

module Folio
  module HtmlSanitization
    class ModelTest < ActiveSupport::TestCase
      class FileWithSanitizationConfig < Folio::File
        def folio_html_sanitization_config
          {
            enabled: true,
            attributes: {
              author: :string,
              description: :unsafe_html,
              alt: -> (value) { value.upcase },
              attribution_source: :rich_text,
              remote_services_data: :unsafe_html,
            }
          }
        end
      end

      test "sanitizes input" do
        file = FileWithSanitizationConfig.new(author: unsafe_input,
                                              alt: unsafe_input,
                                              description: unsafe_input,
                                              attribution_source: unsafe_input,
                                              file_width: 123,
                                              additional_data: {
                                                "foo" => "bar & baz",
                                                "html" => unsafe_input,
                                                "nested" => {
                                                  "html" => unsafe_input,
                                                }
                                              },
                                              remote_services_data: {
                                                "foo" => "bar & baz",
                                                "html" => unsafe_input,
                                                "nested" => {
                                                  "html" => unsafe_input,
                                                }
                                              },
                                              file_metadata: { "no" => "harm here" },
                                              site: get_any_site)

        # trigger sanitization in before_validation
        file.valid?

        assert_equal(input_sanitized_as_string,
                     file.author,
                     "author: :string - HTML tags should be removed, but symbols such as & < > should be preserved")

        assert_equal("<P>FIXED&NBSP;SPACE SCRIPT-<SCRIPT>ALERT('XSS')</SCRIPT> ABSOLUTE-A-<A HREF=\"HTTPS://WWW.GOOGLE.COM/\" TARGET=\"_BLANK\" REL=\"NOOPENER NOREFERRER\">A</A> RELATIVE-A-<A HREF=\"/FOO\" TARGET=\"_SELF\" REL=\"NOFOLLOW\">A</A> HASH-A-<A HREF=\"#FOO\" TARGET=\"_PARENT\" REL=\"BOOKMARK\">A</A> XSS-A-<A HREF=\"JAVASCRIPT:ALERT('XSS')\" TARGET=\"_BLANK\" REL=\"NOOPENER\">A</A> IMG-<IMG ONERROR=\"ALERT('XSS')\"> INPUT-<INPUT ONFOCUS=\"ALERT('XSS')\"> BAR & BAZ LT< GT></P>",
                     file.alt,
                     "alt: proc - proc should be used to transform the value")

        assert_equal(unsafe_input,
                     file.description,
                     "description: :unsafe_html - no sanitization should be applied")

        assert_equal(input_sanitized_as_rich_text,
                     file.attribution_source,
                     "attribution_source: :rich_text - HTML should be whitelisted, symbols such as & < > should be preserved, but converted to HTML entities")

        assert_equal(123,
                     file.file_width,
                     "integer field should not be handled")

        assert_equal({ "foo" => "bar & baz", "html" => input_sanitized_as_string, "nested" => { "html" => input_sanitized_as_string } },
                     file.additional_data,
                     "additional_data - for each value in JSON, HTML tags should be removed, but symbols such as & < > should be preserved")

        assert_equal({ "foo" => "bar & baz", "html" => unsafe_input, "nested" => { "html" => unsafe_input } },
                     file.remote_services_data,
                     "remote_services_data: :unsafe_html - no sanitization should be applied")

        assert_equal({ "no" => "harm here" },
                     file.file_metadata,
                     "file_metadata - no sanitization should be applied as the value is safe already")
      end

      test "sanitizes atom input" do
        atom = create_atom(Dummy::Atom::Contents::Text, content: unsafe_input)
        assert_equal input_sanitized_as_rich_text, atom.content

        atom = create_atom(Dummy::Atom::Contents::Title, title: unsafe_input)
        assert_equal input_sanitized_as_string, atom.title
      end

      test "sanitizes tags" do
        taggable = create(:folio_file_image)
        taggable.tag_list.add("tag1<script>alert('xss')</script>")
        taggable.save!

        assert_equal "tag1alert('xss')", taggable.reload.tag_list.to_s, "#{taggable.class} should have the tag_list sanitized"

        taggable.tag_list.add("tag2")
        taggable.save!

        assert_equal "tag1alert('xss'), tag2", taggable.reload.tag_list.to_s, "#{taggable.class} should have the tag_list sanitized"
      end

      test "sanitizes tiptap_content" do
        Folio::Page.stub(:has_folio_tiptap?, true) do
          page = create(:folio_page, tiptap_content: { Folio::Tiptap::TIPTAP_CONTENT_JSON_STRUCTURE[:content] => {
            "type" => "doc",
            "content" => [
              {
                "type" => "paragraph",
                "content" => [{ "type" => "text", "text" => "<p>html!</p><script>alert('foo')</script>" }]
              },
              {
                "type" => "folioTiptapNode",
                "attrs" => {
                  "type" => "Dummy::Tiptap::Node::Embed",
                  "data" => {
                    "folio_embed_data" => {
                      "active" => unsafe_input,
                      "url" => unsafe_input,
                      "type" => unsafe_input,
                      "foo" => unsafe_input,
                    }
                  },
                }
              },
              {
                "type" => "folioTiptapNode",
                "attrs" => {
                  "type" => "Dummy::Tiptap::Node::Embed",
                  "data" => {
                    "folio_embed_data" => {
                      "active" => true,
                      "url" => "https://www.youtube.com/watch?v={id}",
                      "foo" => unsafe_input,
                      "type" => "youtube",
                    }
                  },
                }
              },
              {
                "type" => "folioTiptapNode",
                "attrs" => {
                  "type" => "Dummy::Tiptap::Node::Embed",
                  "data" => {
                    "folio_embed_data" => {
                      "active" => true,
                      "html" => unsafe_input,
                    }
                  },
                }
              },
              {
                "type" => "folioTiptapNode",
                "attrs" => {
                  "type" => "Dummy::Tiptap::Node::Embed",
                  "data" => {
                    "folio_embed_data" => {
                      "active" => true,
                      "url" => "https://www.youtube.com/watch?v={id}",
                      "foo" => unsafe_input,
                      "type" => "unsupported",
                    }
                  },
                }
              },
            ]
          } })

          content = page.tiptap_content[Folio::Tiptap::TIPTAP_CONTENT_JSON_STRUCTURE[:content]]["content"]

          assert_equal("paragraph", content[0]["type"])
          assert_equal([{ "type" => "text", "text" => "html!alert('foo')" }], content[0]["content"])

          assert_equal("folioTiptapNode", content[1]["type"])
          assert_equal("Dummy::Tiptap::Node::Embed", content[1]["attrs"]["type"])
          assert_nil(content[1]["attrs"]["data"]["folio_embed_data"])

          assert_equal("folioTiptapNode", content[2]["type"])
          assert_equal("Dummy::Tiptap::Node::Embed", content[2]["attrs"]["type"])
          assert_equal(true, content[2]["attrs"]["data"]["folio_embed_data"]["active"])
          assert_equal("https://www.youtube.com/watch?v={id}", content[2]["attrs"]["data"]["folio_embed_data"]["url"])
          assert_nil(content[2]["attrs"]["data"]["folio_embed_data"]["foo"])
          assert_equal("youtube", content[2]["attrs"]["data"]["folio_embed_data"]["type"])

          assert_equal("folioTiptapNode", content[3]["type"])
          assert_equal("Dummy::Tiptap::Node::Embed", content[3]["attrs"]["type"])
          assert_equal(true, content[3]["attrs"]["data"]["folio_embed_data"]["active"])
          assert_equal(unsafe_input, content[3]["attrs"]["data"]["folio_embed_data"]["html"])

          assert_equal("folioTiptapNode", content[4]["type"])
          assert_equal("Dummy::Tiptap::Node::Embed", content[4]["attrs"]["type"])
          assert_equal(true, content[4]["attrs"]["data"]["folio_embed_data"]["active"])
          assert_nil(content[4]["attrs"]["data"]["folio_embed_data"]["url"])
          assert_nil(content[4]["attrs"]["data"]["folio_embed_data"]["foo"])
          assert_nil(content[4]["attrs"]["data"]["folio_embed_data"]["type"])
        end
      end

      private
        def unsafe_input
          "<p>fixed&nbsp;space script-<script>alert('xss')</script> absolute-a-<a href=\"https://www.google.com/\" target=\"_blank\" rel=\"noopener noreferrer\">a</a> relative-a-<a href=\"/foo\" target=\"_self\" rel=\"nofollow\">a</a> hash-a-<a href=\"#foo\" target=\"_parent\" rel=\"bookmark\">a</a> xss-a-<a href=\"javascript:alert('xss')\" target=\"_blank\" rel=\"noopener\">a</a> img-<img onerror=\"alert('xss')\"> input-<input onfocus=\"alert('xss')\"> bar & baz lt< gt></p>"
        end

        def utf_nbsp
          " "
        end

        def input_sanitized_as_string
          "fixed#{utf_nbsp}space script-alert('xss') absolute-a-a relative-a-a hash-a-a xss-a-a img- input- bar & baz lt< gt>"
        end

        def input_sanitized_as_rich_text
          "<p>fixed&nbsp;space script-alert('xss') absolute-a-<a href=\"https://www.google.com/\" target=\"_blank\" rel=\"noopener noreferrer\">a</a> relative-a-<a href=\"/foo\" target=\"_self\" rel=\"nofollow\">a</a> hash-a-<a href=\"#foo\" target=\"_parent\" rel=\"bookmark\">a</a> xss-a-<a target=\"_blank\" rel=\"noopener\">a</a> img-<img> input- bar &amp; baz lt&lt; gt&gt;</p>"
        end
    end
  end
end
