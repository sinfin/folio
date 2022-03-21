# frozen_string_literal: true

class Folio::Console::ConsoleNoteSerializer
  include FastJsonapi::ObjectSerializer

  attributes :id,
             :content,
             :position,
             :due_at,
             :closed_at,
             :created_by_id,
             :closed_by_id,
             :_destroy
end
