# frozen_string_literal: true

class Folio::Console::ClipboardCopyCell < Folio::ConsoleCell
  def show
    render if model.present?
  end

  def html_left
    icons = [
      folio_icon(:content_copy, height: 16, class: "f-c-clipboard-copy__ico"),
      folio_icon(:check, height: 16, class: "f-c-clipboard-copy__done"),
    ].join(" ")
    content_tag(:div, icons, class: "f-c-clipboard-copy__icons")
  end
end
