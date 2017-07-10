class Folio::Category < Folio::Node

  has_many :translations, class_name: "Folio::CategoryTranslation"

  before_validation do
    self.locale = self.site.locale if locale.nil?
  end

end
