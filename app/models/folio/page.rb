# frozen_string_literal: true

class Folio::Page < Folio::Node
  has_many :translations, class_name: 'Folio::PageTranslation'
end
