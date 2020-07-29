# frozen_string_literal: true

class Folio::Console::FileListCell < Folio::ConsoleCell
  def show
    return nil if model.blank?
    render
  end

  def as_documents?
    model.any? { |file| !file.respond_to?(:thumb) }
  end
end
