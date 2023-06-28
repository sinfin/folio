# frozen_string_literal: true

module Folio::Console::Report::Dsl
  def report_item(key, content)
    @report_html += content_tag(:div, content, class: "f-c-report__item f-c-report__item--#{key}")
  end

  def title(string, tag: :h2)
    report_item(:title,
                content_tag(tag, string, class: "m-0"))
  end

  def text(string, tag: :p)
    report_item(:text,
                content_tag(tag, string, class: "m-0 small text-muted"))
  end

  def hr
    report_item(:hr,
                tag(:hr, class: "m-0"))
  end

  def box(hash)
    report_item(:box,
                cell("folio/console/report/box", hash))
  end

  def boxes(hashes)
    report_item(:boxes,
                cell("folio/console/report/boxes", hashes))
  end

  def area_chart(hash)
    report_item(:area_chart,
                cell("folio/console/report/area_chart", hash))
  end

  def area_charts(hashes)
    report_item(:area_charts,
                cell("folio/console/report/area_charts", hashes))
  end
end