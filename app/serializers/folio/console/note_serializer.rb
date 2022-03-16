# frozen_string_literal: true

class Folio::Console::NoteSerializer
  include FastJsonapi::ObjectSerializer

  attributes :id,
             :content,
             :closed_at,
             :position,
             :_destroy
end
