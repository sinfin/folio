# frozen_string_literal: true

class Folio::Console::Dummy::PlaygroundsController < Folio::Console::BaseController
  def players
  end

  def pickers
  end

  def report
  end

  def modals
  end

  def alerts
  end

  def console_notes
    @page = Dummy::Page::WithConsoleNotes.last || Dummy::Page::WithConsoleNotes.create!(title: "Page with console notes")
  end

  def update_console_notes
    @page = Dummy::Page::WithConsoleNotes.last
    @page.update!(params.require(:page).permit(*console_notes_strong_params))
    redirect_to main_app.console_notes_console_dummy_playground_path
  end

  def force_use_react_modals?
    true
  end
end
