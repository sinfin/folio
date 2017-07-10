class Folio::CategoryTranslation < Folio::Category

  # Relations
  belongs_to :category, class_name: "Folio::Category", foreign_key: :original_id

  # Validations
  validates :locale, uniqueness: { scope: :category }

end
