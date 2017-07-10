# frozen_string_literal: true

class Folio::PageTranslation < Folio::Page
  # Relations
  belongs_to :page, class_name: 'Folio::Page', foreign_key: :original_id

  # Validations
  validates :locale, uniqueness: { scope: :page }
end
