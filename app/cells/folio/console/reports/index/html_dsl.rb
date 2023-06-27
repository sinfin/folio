# frozen_string_literal: true

module Folio::Console::Reports::Index::HtmlDsl
  def title(string, tag: :h2)
    @report_html += content_tag(tag, string, class: "f-c-reports-index__title f-c-reports-index__title--#{tag}")
  end

  def text(string, tag: :p)
    @report_html += content_tag(tag, string, class: "f-c-reports-index__text f-c-reports-index__text--#{tag}")
  end

  def hr
    @report_html += tag(:hr, class: "f-c-reports-index__hr")
  end

  def box
    @report_html += tag(:hr, class: "f-c-reports-index__hr")
  end
end
