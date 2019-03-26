# frozen_string_literal: true

class Folio::Version < PaperTrail::Version
  belongs_to :account, class_name: 'Folio::Account',
                       foreign_key: :whodunnit,
                       optional: true
end
