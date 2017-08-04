# frozen_string_literal: true

class Folio::Category < Folio::Node
  has_many :translations, class_name: 'Folio::CategoryTranslation'
end
