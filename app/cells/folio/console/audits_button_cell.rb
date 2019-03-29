# frozen_string_literal: true

class Folio::Console::AuditsButtonCell < Folio::ConsoleCell
  def show
    render unless model.new_record?
  end

  def audits_url
    url_for([:console, model, :audits])
  end
end
