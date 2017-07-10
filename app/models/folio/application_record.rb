# frozen_string_literal: true

module Folio
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end
end
