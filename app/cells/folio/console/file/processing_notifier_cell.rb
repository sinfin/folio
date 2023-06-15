# frozen_string_literal: true

class Folio::Console::File::ProcessingNotifierCell < Folio::ConsoleCell
  def show
    render if model.present? && !model.ready?
  end

  def data
    {
      "controller" => "f-c-file-processing-notifier",
      "file" => Folio::Console::FileSerializer.new(model).serializable_hash[:data].to_json,
      "file-id" => model.id,
      "pending-append" => options[:pending_append],
    }
  end
end
