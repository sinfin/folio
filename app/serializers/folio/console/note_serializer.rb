# frozen_string_literal: true

class Folio::Console::NoteSerializer
  include FastJsonapi::ObjectSerializer

  attributes :id,
             :content,
             :position,
             :closed_at,
             :_destroy
end
