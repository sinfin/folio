# frozen_string_literal: true

class Dummy::Atom::TextCell < ApplicationCell
  def show
    render if model.content.present?
  end

  def content
    if model.content.present? && model.content.include?("<table>")
      content_with_table
    else
      model.content
    end
  end

  def content_with_table
    parsed = Nokogiri::HTML::DocumentFragment.parse(model.content)
    parsed.search("table")
          .wrap('<div class="d-atom-text__table-wrap" />')
    parsed.to_html
  end

  def highlight?
    model.highlight.present?
  end

  def highlight_class_name
    if highlight?
      "p-gg d-atom-text__highlight d-atom-text__highlight--#{model.highlight} d-rich-text--chomp"
    end
  end
end
