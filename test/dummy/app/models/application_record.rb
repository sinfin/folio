# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  include Folio::Filterable
  include Folio::NillifyBlanks
  include Folio::ToLabel

  self.abstract_class = true
end
