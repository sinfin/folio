# frozen_string_literal: true

module Folio
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true

    include Filterable
    include Sortable
    include RecursiveSubclasses
    include NillifyBlanks
  end
end
