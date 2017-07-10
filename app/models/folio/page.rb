# frozen_string_literal: true

class Folio::Page < Folio::Node
  has_many :translations, class_name: 'Folio::PageTranslation'

  before_validation do
    self.locale = site.locale if locale.nil?
  end
end
