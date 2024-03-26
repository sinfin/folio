# frozen_string_literal: true

class Folio::Console::Ui::BadgeCell < Folio::ConsoleCell
  def variant
    options[:variant] || "secondary"
  end
end
