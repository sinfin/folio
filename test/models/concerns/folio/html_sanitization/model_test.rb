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
              attribution_source: :richtext,
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

        assert_equal("<P>FIXED&NBSP;SPACE SCRIPT-<SCRIPT>ALERT('XSS')</SCRIPT> ABSOLUTE-A-<A HREF=\"HTTPS://WWW.GOOGLE.COM/\">A</A> RELATIVE-A-<A HREF=\"/FOO\">A</A> HASH-A-<A HREF=\"#FOO\">A</A> XSS-A-<A HREF=\"JAVASCRIPT:ALERT('XSS')\">A</A> IMG-<IMG ONERROR=\"ALERT('XSS')\"> INPUT-<INPUT ONFOCUS=\"ALERT('XSS')\"> BAR & BAZ LT< GT></P>",
                     file.alt,
                     "alt: proc - proc should be used to transform the value")

        assert_equal(unsafe_input,
                     file.description,
                     "description: :unsafe_html - no sanitization should be applied")

        assert_equal(input_sanitized_as_richtext,
                     file.attribution_source,
                     "attribution_source: :richtext - HTML should be whitelisted, symbols such as & < > should be preserved, but converted to HTML entities")

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
        assert_equal input_sanitized_as_richtext, atom.content

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

      private
        def unsafe_input
          "<p>fixed&nbsp;space script-<script>alert('xss')</script> absolute-a-<a href=\"https://www.google.com/\">a</a> relative-a-<a href=\"/foo\">a</a> hash-a-<a href=\"#foo\">a</a> xss-a-<a href=\"javascript:alert('xss')\">a</a> img-<img onerror=\"alert('xss')\"> input-<input onfocus=\"alert('xss')\"> bar & baz lt< gt></p>"
        end

        def utf_nbsp
          " "
        end

        def input_sanitized_as_string
          "fixed#{utf_nbsp}space script-alert('xss') absolute-a-a relative-a-a hash-a-a xss-a-a img- input- bar & baz lt< gt>"
        end

        def input_sanitized_as_richtext
          "<p>fixed#{utf_nbsp}space script-alert('xss') absolute-a-<a href=\"https://www.google.com/\">a</a> relative-a-<a href=\"/foo\">a</a> hash-a-<a href=\"#foo\">a</a> xss-a-<a>a</a> img-<img> input- bar &amp; baz lt&lt; gt&gt;</p>"
        end
    end
  end
end
