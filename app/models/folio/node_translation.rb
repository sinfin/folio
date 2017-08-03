# frozen_string_literal: true

class Folio::NodeTranslation < Folio::Node
  # Relations
  belongs_to :node_original, class_name: 'Folio::Node', foreign_key: :original_id

  # Validations
  validates :locale, uniqueness: { scope: :node }

  # Casting ActiveRecord class to an original Node class
  def cast
    self.becomes(node_original.class)
  end

  def translate(locale)
    case locale
    when locale == self.locale
      cast
    when node_original.translations.where(locale: locale).exists?
      self.translations.find_by(locale: locale).cast
    else
      node_original.cast
    end
  end
end
