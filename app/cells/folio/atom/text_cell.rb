# frozen_string_literal: true

class Folio::Atom::TextCell < Folio::ApplicationCell
  include Folio::CstypoHelper

  def show
    render if model.content.present?
  end

  def content
    if model.content.present? && model.content.include?('<table>')
      content_with_table
    else
      model.content
    end
  end

  def content_with_table
    parsed = Nokogiri::HTML::DocumentFragment.parse(model.content)
    parsed.search('table')
          .wrap('<div class="folio-atom-text__table-wrap" />')
    parsed.to_html
  end
end
