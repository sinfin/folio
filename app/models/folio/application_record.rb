# frozen_string_literal: true

class Folio::ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  include Folio::Filterable
  include Folio::NillifyBlanks
  include Folio::RecursiveSubclasses
  include Folio::ToLabel
  include Folio::Sortable
end
