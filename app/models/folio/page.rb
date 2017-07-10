class Folio::Page < Folio::Node

  has_many :translations, class_name: "Folio::PageTranslation"

  before_validation do
    self.locale = self.site.locale if locale.nil?
  end

end
