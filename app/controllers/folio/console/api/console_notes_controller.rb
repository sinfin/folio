# frozen_string_literal: true

class Folio::Console::Api::ConsoleNotesController < Folio::Console::Api::BaseController
  folio_console_controller_for "Folio::ConsoleNote"

  def toggle_closed_at
    if [true, "true"].include?(params[:closed]) && !@console_note.closed_at?
      @console_note.update(closed_at: Time.current,
                           closed_by: current_account)
    elsif [false, "false"].include?(params[:closed]) && @console_note.closed_at
      @console_note.update(closed_at: nil,
                           closed_by: nil)
    end

    if @console_note.valid?
      render json: modify_valid_hash_to_render({
        data: {
          catalogue_tooltip: cell("folio/console/console_notes/catalogue_tooltip", @console_note.target).show,
        },
      }).compact
    else
      render_invalid @console_note
    end
  end

  private
    def modify_valid_hash_to_render(hash)
      # to be overriden in app if need be
      hash
    end
end
