# frozen_string_literal: true

require "test_helper"

module Folio
  module HtmlSanitization
    class ModelTest < ActiveSupport::TestCase
      class PageWithSanitizationConfig < Folio::Page
        def folio_html_sanitization_config
          {
            enabled: true,
            attributes: {
              title: :string,
              meta_description: :unsafe_html,
              meta_title: -> (value) { value.upcase },
              perex: :richtext,
            }
          }
        end
      end

      test "sanitizes input" do
        unsafe_input = "<p>fixed&nbsp;space script-<script>alert('xss')</script> absolute-a-<a href=\"https://www.google.com/\">a</a> relative-a-<a href=\"/foo\">a</a> hash-a-<a href=\"#foo\">a</a> xss-a-<a href=\"javascript:alert('xss')\">a</a> img-<img onerror=\"alert('xss')\"> input-<input onfocus=\"alert('xss')\"> bar & baz lt< gt></p>"

        page = PageWithSanitizationConfig.new(title: unsafe_input,
                                              meta_title: unsafe_input,
                                              meta_description: unsafe_input,
                                              perex: unsafe_input,
                                              site: get_any_site)
        assert page.valid?

        utf_nbsp = " "

        assert_equal("fixed#{utf_nbsp}space script-alert('xss') absolute-a-a relative-a-a hash-a-a xss-a-a img- input- bar & baz lt< gt>", page.title)
        assert_equal("<P>FIXED&NBSP;SPACE SCRIPT-<SCRIPT>ALERT('XSS')</SCRIPT> ABSOLUTE-A-<A HREF=\"HTTPS://WWW.GOOGLE.COM/\">A</A> RELATIVE-A-<A HREF=\"/FOO\">A</A> HASH-A-<A HREF=\"#FOO\">A</A> XSS-A-<A HREF=\"JAVASCRIPT:ALERT('XSS')\">A</A> IMG-<IMG ONERROR=\"ALERT('XSS')\"> INPUT-<INPUT ONFOCUS=\"ALERT('XSS')\"> BAR & BAZ LT< GT></P>", page.meta_title)
        assert_equal(unsafe_input, page.meta_description)
        assert_equal("<p>fixed#{utf_nbsp}space script-alert('xss') absolute-a-<a href=\"https://www.google.com/\">a</a> relative-a-<a href=\"/foo\">a</a> hash-a-<a href=\"#foo\">a</a> xss-a-<a>a</a> img-<img> input- bar &amp; baz lt&lt; gt&gt;</p>", page.perex)
      end
    end
  end
end
