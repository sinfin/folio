# frozen_string_literal: true

require 'redcarpet'

module Folio
  module MarkdownHelper
    def markdown_to_html(text)
      return "" if text.blank?

      renderer = Redcarpet::Render::HTML.new(
        hard_wrap: true,
        autolink: true,
        no_intra_emphasis: true,
        fenced_code_blocks: true,
        tables: true,
        with_toc_data: true
      )

      markdown = Redcarpet::Markdown.new(renderer,
        autolink: true,
        tables: true,
        fenced_code_blocks: true,
        no_intra_emphasis: true,
        strikethrough: true,
        superscript: true,
        highlight: true
      )

      markdown.render(text).html_safe
    end
  end
end 