# frozen_string_literal: true

class Folio::Console::Merges::Index::FooterCell < Folio::ConsoleCell
  def merge_url
    controller.new_console_merge_path(model, "X", "Y", url: request.fullpath)
  end
end
