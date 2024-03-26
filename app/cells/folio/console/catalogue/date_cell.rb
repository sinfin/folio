# frozen_string_literal: true

class Folio::Console::Catalogue::DateCell < Folio::ConsoleCell
  class_name "f-c-catalogue-date", :alert?

  def show
    render if model.present?
  end

  def alert?
    if options[:alert_threshold]
      model < options[:alert_threshold].ago
    end
  end
end
