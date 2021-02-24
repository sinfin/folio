# frozen_string_literal: true

logger = Logger.new(STDOUT)

if Folio::Atom::Base.exists?(type: "Folio::Atom::Text")
  logger.error "Folio::Atom::Text is no longer defined. You have to create a new atom using 'rails g folio:prepared_atom text' and run Folio::Atom::Base.where(type: 'Folio::Atom::Text').update_all(type: 'NEWTYPE')"
end

if Folio::Atom::Base.exists?(type: "Folio::Atom::Title")
  logger.error "Folio::Atom::Title is no longer defined. You have to create a new atom using 'rails g folio:prepared_atom title' and run Folio::Atom::Base.where(type: 'Folio::Atom::Title').update_all(type: 'NEWTYPE')"
end
