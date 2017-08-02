module Folio
  class File < ApplicationRecord
    dragonfly_accessor :file
    validates :file, presence: true
  end
end
