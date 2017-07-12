# frozen_string_literal: true

require_dependency 'folio/concerns/filterable'
require_dependency 'folio/concerns/sortable'

module Folio
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true

    include Filterable
    include Sortable
  end
end
